use regex::Regex;

/// マスキング設定を保持する構造体
pub struct Masker {
    mask_email: bool,
    mask_phone: bool, // 追加: 電話番号マスキングフラグ
    mask_char: char,  // 追加: マスキングに使用する文字
    email_regex: Regex,
    phone_regex: Regex, // 追加
}

impl Masker {
    pub fn new() -> Self {
        Self {
            mask_email: false,
            mask_phone: false,
            mask_char: '*', // デフォルトは '*'
            
            // メールアドレス用 (前回と同じ)
            email_regex: Regex::new(r"(?P<local>[a-zA-Z0-9._%+-]+)@(?P<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})")
                .expect("Invalid email regex"),
            
            // 電話番号用 (日本の一般的なハイフン付き番号に対応)
            // 例: 090-1234-5678, 03-1234-5678
            // (?P<head>...) は「市外局番」などのキャプチャグループ名です
            phone_regex: Regex::new(r"(?P<head>0\d{1,3})-(?P<mid>\d{2,4})-(?P<tail>\d{3,4})")
                .expect("Invalid phone regex"),
        }
    }

    /// メールアドレスを隠す設定
    pub fn mask_emails(mut self) -> Self {
        self.mask_email = true;
        self
    }

    /// 電話番号を隠す設定 (New)
    pub fn mask_phones(mut self) -> Self {
        self.mask_phone = true;
        self
    }

    /// マスキングに使う文字を変更する (New)
    /// 例: '*' ではなく 'x' にしたい場合など
    pub fn with_mask_char(mut self, c: char) -> Self {
        self.mask_char = c;
        self
    }

    /// 実行処理
    pub fn process(&self, input: &str) -> String {
        let mut result = input.to_string();

        // 1. メールアドレスの処理
        if self.mask_email {
            result = self.email_regex.replace_all(&result, |caps: &regex::Captures| {
                let local_part = &caps["local"];
                let domain_part = &caps["domain"];
                
                let masked_local = if local_part.len() > 1 {
                    let first_char = local_part.chars().next().unwrap();
                    // self.mask_char を使用するように変更
                    let stars = self.mask_char.to_string().repeat(local_part.len() - 1);
                    format!("{}{}", first_char, stars)
                } else {
                    self.mask_char.to_string()
                };

                format!("{}@{}", masked_local, domain_part)
            }).to_string();
        }

        // 2. 電話番号の処理 (New)
        if self.mask_phone {
            result = self.phone_regex.replace_all(&result, |caps: &regex::Captures| {
                let head = &caps["head"]; // 市外局番 (例: 090)
                let mid = &caps["mid"];   // 市内局番 (例: 1234)
                let tail = &caps["tail"]; // 加入者番号 (例: 5678)

                // マスキングロジック:
                // 市外局番は見せて、それ以降をすべてマスクする
                // 例: 090-****-****
                let masked_mid = self.mask_char.to_string().repeat(mid.len());
                let masked_tail = self.mask_char.to_string().repeat(tail.len());

                format!("{}-{}-{}", head, masked_mid, masked_tail)
            }).to_string();
        }

        result
    }
}

// --- テストコード ---
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mask_email_custom_char() {
        // 'x' でマスクするテスト
        let masker = Masker::new().mask_emails().with_mask_char('x');
        let input = "alice@example.com";
        let expected = "axxxx@example.com";
        
        assert_eq!(masker.process(input), expected);
    }

    #[test]
    fn test_mask_phone_jp() {
        // 電話番号のテスト
        let masker = Masker::new().mask_phones();
        let input = "私の番号は 090-1234-5678 です。";
        // 090 は残して、あとは * になる
        let expected = "私の番号は 090-****-**** です。";
        
        assert_eq!(masker.process(input), expected);
    }

    #[test]
    fn test_mask_mixed() {
        // メールと電話の両方をマスク
        let masker = Masker::new().mask_emails().mask_phones();
        let input = "Tel: 03-9999-0000, Email: bob@test.com";
        let expected = "Tel: 03-****-****, Email: b**@test.com";
        
        assert_eq!(masker.process(input), expected);
    }
}
