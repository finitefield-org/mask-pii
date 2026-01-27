use regex::Regex;

/// マスキング設定を保持する構造体
pub struct Masker {
    // 将来的に電話番号やクレカなどのフラグもここに追加します
    mask_email: bool,
    email_regex: Regex,
}

impl Masker {
    /// デフォルトの設定で新しいMaskerを作成
    pub fn new() -> Self {
        Self {
            mask_email: false,
            // 簡易的なメールアドレス検出用正規表現
            // 本格的なものはもっと複雑ですが、まずはこれで十分です
            email_regex: Regex::new(r"(?P<local>[a-zA-Z0-9._%+-]+)@(?P<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})")
                .expect("Invalid regex"),
        }
    }

    /// メールアドレスのマスキングを有効にするビルダーメソッド
    pub fn mask_emails(mut self) -> Self {
        self.mask_email = true;
        self
    }

    /// テキストを処理して、マスキングされた文字列を返す
    pub fn process(&self, input: &str) -> String {
        let mut result = input.to_string();

        if self.mask_email {
            // Regexを使って置換処理を行う
            result = self.email_regex.replace_all(&result, |caps: &regex::Captures| {
                let local_part = &caps["local"];
                let domain_part = &caps["domain"];
                
                // マスキングロジック:
                // ローカルパート（@の前）の先頭1文字だけ残して、あとは '*' にする
                let masked_local = if local_part.len() > 1 {
                    let first_char = local_part.chars().next().unwrap();
                    let stars = "*".repeat(local_part.len() - 1);
                    format!("{}{}", first_char, stars)
                } else {
                    "*".to_string()
                };

                format!("{}@{}", masked_local, domain_part)
            }).to_string();
        }

        result
    }
}

// --- テストコード (ここが開発のメインフィールドです) ---
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mask_email_basic() {
        let masker = Masker::new().mask_emails();
        let input = "Contact me at alice@example.com please.";
        let expected = "Contact me at a****@example.com please.";
        
        assert_eq!(masker.process(input), expected);
    }

    #[test]
    fn test_mask_email_short() {
        let masker = Masker::new().mask_emails();
        let input = "Email: a@b.com";
        // 1文字の場合はすべて隠すロジックにしているため
        let expected = "Email: *@b.com"; 
        
        assert_eq!(masker.process(input), expected);
    }

    #[test]
    fn test_no_masking() {
        // mask_emails() を呼ばない場合
        let masker = Masker::new();
        let input = "alice@example.com";
        assert_eq!(masker.process(input), input);
    }
}
