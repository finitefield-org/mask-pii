use regex::Regex;

pub struct Masker {
    mask_email: bool,
    mask_phone: bool,
    mask_char: char,
    email_regex: Regex,
    phone_regex: Regex,
}

impl Masker {
    pub fn new() -> Self {
        Self {
            mask_email: false,
            mask_phone: false,
            mask_char: '*',
            
            email_regex: Regex::new(r"(?P<local>[a-zA-Z0-9._%+-]+)@(?P<domain>[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})")
                .expect("Invalid email regex"),
            
            // --- グローバル対応の電話番号正規表現 ---
            // 解説:
            // 1. (?:\+?\d{1,4}[\s-]?)?  -> 国番号 (+81 や 1) があるかもしれない
            // 2. (?:\(\d{1,5}\)|\d{1,5}) -> 市外局番 (カッコ付き or なし)
            // 3. [\s-]?\d{1,5}[\s-]?\d{3,5} -> 市内局番と加入者番号
            // これらを組み合わせた、少し緩めの正規表現です。
            phone_regex: Regex::new(r"(?x) # (?x)はコメント許可モード
                (?:
                    \+?\d{1,4}    # 国番号 (例: +81)
                    [\s-]?
                )?
                (?:
                    \(\d{1,5}\)   # カッコ付き市外局番
                    |
                    \d{1,5}       # カッコなし
                )
                [\s-]?
                \d{1,5}           # 番号ブロック1
                [\s-]?
                \d{3,5}           # 番号ブロック2
            ").expect("Invalid phone regex"),
        }
    }

    pub fn mask_emails(mut self) -> Self {
        self.mask_email = true;
        self
    }

    pub fn mask_phones(mut self) -> Self {
        self.mask_phone = true;
        self
    }

    pub fn with_mask_char(mut self, c: char) -> Self {
        self.mask_char = c;
        self
    }

    pub fn process(&self, input: &str) -> String {
        let mut result = input.to_string();

        // 1. Email処理 (変更なし)
        if self.mask_email {
            result = self.email_regex.replace_all(&result, |caps: &regex::Captures| {
                let local_part = &caps["local"];
                let domain_part = &caps["domain"];
                
                let masked_local = if local_part.len() > 1 {
                    let first_char = local_part.chars().next().unwrap();
                    let stars = self.mask_char.to_string().repeat(local_part.len() - 1);
                    format!("{}{}", first_char, stars)
                } else {
                    self.mask_char.to_string()
                };
                format!("{}@{}", masked_local, domain_part)
            }).to_string();
        }

        // 2. 電話番号処理 (ロジック刷新)
        if self.mask_phone {
            result = self.phone_regex.replace_all(&result, |caps: &regex::Captures| {
                let matched_str = &caps[0]; // マッチした電話番号全体
                
                // 数字だけを数える
                let digit_count = matched_str.chars().filter(|c| c.is_ascii_digit()).count();
                
                // 数字が見つかった回数を追跡するカウンタ
                let mut current_digit_index = 0;
                
                // マッチした文字列を1文字ずつ再構築する
                matched_str.chars().map(|c| {
                    if c.is_ascii_digit() {
                        current_digit_index += 1;
                        // ロジック: 末尾4桁以外はすべてマスクする
                        // (ただし、総桁数が6桁以下の短い番号なら全部隠すなどの調整も可能)
                        if digit_count > 4 && current_digit_index <= digit_count - 4 {
                            self.mask_char
                        } else {
                            c // 末尾4桁はそのまま表示
                        }
                    } else {
                        c // ハイフンやスペース、カッコはそのまま残す
                    }
                }).collect::<String>()
            }).to_string();
        }

        result
    }
}

// --- グローバル対応テスト ---
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_global_phones() {
        let masker = Masker::new().mask_phones();

        // 日本 (ハイフンあり)
        assert_eq!(
            masker.process("Tel: 090-1234-5678"),
            "Tel: ***-****-5678" // 末尾4桁以外隠れる
        );

        // 米国 (カッコあり)
        assert_eq!(
            masker.process("Call (555) 123-4567 now"),
            "Call (***) ***-4567 now"
        );

        // 国際電話 (+付き)
        assert_eq!(
            masker.process("Intl: +81 3 1234 5678"),
            "Intl: +** * **** 5678"
        );
        
        // 桁数が少ない場合 (末尾4桁だけ残る)
        assert_eq!(
            masker.process("Short: 12-3456"),
            "Short: **-3456"
        );
    }
}
