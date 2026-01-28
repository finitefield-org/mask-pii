import Test.Hspec
import MaskPII

main :: IO ()
main = hspec $ do
  describe "Email masking" $ do
    let masker = maskEmails newMasker
        cases =
          [ ("alice@example.com", "a****@example.com")
          , ("a@b.com", "*@b.com")
          , ("ab@example.com", "a*@example.com")
          , ("a.b+c_d@example.co.jp", "a******@example.co.jp")
          , ("Contact: alice@example.com.", "Contact: a****@example.com.")
          , ("alice@example.com and bob@example.org", "a****@example.com and b**@example.org")
          , ("alice@example", "alice@example")
          , ("alice@localhost", "alice@localhost")
          , ("alice@@example.com", "alice@@example.com")
          , ("first.last+tag@sub.domain.com", "f*************@sub.domain.com")
          ]
    mapM_ (\(input, expected) ->
      it ("masks " ++ input) $
        process masker input `shouldBe` expected
      ) cases

  describe "Phone masking" $ do
    let masker = maskPhones newMasker
        cases =
          [ ("090-1234-5678", "***-****-5678")
          , ("Call (555) 123-4567", "Call (***) ***-4567")
          , ("Intl: +81 3 1234 5678", "Intl: +** * **** 5678")
          , ("+1 (800) 123-4567", "+* (***) ***-4567")
          , ("1234", "1234")
          , ("12345", "*2345")
          , ("12-3456", "**-3456")
          , ("Tel: 090-1234-5678 ext. 99", "Tel: ***-****-5678 ext. 99")
          , ("Numbers: 111-2222 and 333-4444", "Numbers: ***-2222 and ***-4444")
          , ("abcdef", "abcdef")
          , ("+", "+")
          , ("(12) 345 678", "(**) **5 678")
          ]
    mapM_ (\(input, expected) ->
      it ("masks " ++ input) $
        process masker input `shouldBe` expected
      ) cases

  describe "Combined masking" $ do
    let masker = maskPhones (maskEmails newMasker)
        cases =
          [ ("Contact: alice@example.com or 090-1234-5678.", "Contact: a****@example.com or ***-****-5678.")
          , ("Email bob@example.org, phone +1 (800) 123-4567", "Email b**@example.org, phone +* (***) ***-4567")
          ]
    mapM_ (\(input, expected) ->
      it ("masks " ++ input) $
        process masker input `shouldBe` expected
      ) cases

  describe "Custom mask character" $ do
    let masker = withMaskChar '#' (maskPhones (maskEmails newMasker))
        cases =
          [ ("alice@example.com", "a####@example.com")
          , ("090-1234-5678", "###-####-5678")
          , ("Contact: alice@example.com or 090-1234-5678.", "Contact: a####@example.com or ###-####-5678.")
          ]
    mapM_ (\(input, expected) ->
      it ("masks " ++ input) $
        process masker input `shouldBe` expected
      ) cases

  describe "Masker configuration" $ do
    it "does nothing when no masks are enabled" $
      process newMasker "alice@example.com" `shouldBe` "alice@example.com"

    it "masks only emails when email masking is enabled" $
      process (maskEmails newMasker) "alice@example.com" `shouldBe` "a****@example.com"

    it "masks only phones when phone masking is enabled" $
      process (maskPhones newMasker) "090-1234-5678" `shouldBe` "***-****-5678"
