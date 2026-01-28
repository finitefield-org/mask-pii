import MaskPII (newMasker, maskEmails, maskPhones, withMaskChar, process)

main :: IO ()
main = do
  let masker = withMaskChar '#'
             $ maskPhones
             $ maskEmails newMasker
  putStrLn $ process masker "Contact: alice@example.com or 090-1234-5678."
