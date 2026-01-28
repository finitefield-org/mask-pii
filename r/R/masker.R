#' Create a configurable masker for emails and phone numbers.
#'
#' @description
#' Create a masker that can selectively mask emails, phone numbers, or both.
#' The masker uses ASCII character rules and avoids regular expressions for
#' predictable behavior across platforms.
#'
#' @return A masker object with chainable methods: `mask_emails()`,
#'   `mask_phones()`, `with_mask_char()`, and `process()`.
#'
#' @examples
#' masker <- Masker()
#' result <- masker$mask_emails()$mask_phones()$process(
#'   "Contact: alice@example.com or 090-1234-5678."
#' )
#' print(result)
#'
#' @export
Masker <- function() {
  state <- new.env(parent = emptyenv())
  state$mask_email <- FALSE
  state$mask_phone <- FALSE
  state$mask_char <- "*"

  self <- list()

  #' Enable email address masking.
  #' @return The masker instance.
  self$mask_emails <- function() {
    state$mask_email <- TRUE
    self
  }

  #' Enable phone number masking.
  #' @return The masker instance.
  self$mask_phones <- function() {
    state$mask_phone <- TRUE
    self
  }

  #' Set the character used for masking.
  #' @param char A single character to use for masking.
  #' @return The masker instance.
  self$with_mask_char <- function(char) {
    if (is.null(char) || length(char) == 0 || nchar(as.character(char), type = "chars") == 0) {
      state$mask_char <- "*"
    } else {
      value <- as.character(char)
      state$mask_char <- substr(value, 1, 1)
    }
    self
  }

  #' Process input text and mask enabled PII patterns.
  #' @param input_text Input text to scan.
  #' @return The masked text.
  self$process <- function(input_text) {
    text <- as.character(input_text)
    if (!state$mask_email && !state$mask_phone) {
      return(text)
    }

    mask_char <- state$mask_char
    if (is.null(mask_char) || nchar(mask_char, type = "chars") == 0) {
      mask_char <- "*"
    }

    result <- text
    if (state$mask_email) {
      result <- mask_emails_in_text(result, mask_char)
    }
    if (state$mask_phone) {
      result <- mask_phones_in_text(result, mask_char)
    }
    result
  }

  class(self) <- "maskpii_masker"
  self
}

mask_emails_in_text <- function(input_text, mask_char) {
  chars <- strsplit(input_text, "", fixed = TRUE)[[1]]
  n <- length(chars)
  if (n == 0) {
    return(input_text)
  }

  output <- character(0)
  last <- 1
  i <- 1

  while (i <= n) {
    if (chars[i] == "@") {
      local_start <- i
      while (local_start > 1 && is_local_char(chars[local_start - 1])) {
        local_start <- local_start - 1
      }
      local_end <- i - 1

      domain_start <- i + 1
      domain_end <- domain_start
      while (domain_end <= n && is_domain_char(chars[domain_end])) {
        domain_end <- domain_end + 1
      }
      domain_end <- domain_end - 1

      if (local_start <= local_end && domain_start <= domain_end) {
        candidate_end <- domain_end
        matched_end <- 0
        while (candidate_end >= domain_start) {
          domain <- paste0(chars[domain_start:candidate_end], collapse = "")
          if (is_valid_domain(domain)) {
            matched_end <- candidate_end
            break
          }
          candidate_end <- candidate_end - 1
        }

        if (matched_end > 0) {
          if (last <= local_start - 1) {
            output <- c(output, paste0(chars[last:(local_start - 1)], collapse = ""))
          } else if (last == local_start) {
            output <- c(output, "")
          }
          local <- paste0(chars[local_start:local_end], collapse = "")
          domain <- paste0(chars[domain_start:matched_end], collapse = "")
          output <- c(output, mask_local(local, mask_char), "@", domain)
          last <- matched_end + 1
          i <- matched_end + 1
          next
        }
      }
    }
    i <- i + 1
  }

  if (last <= n) {
    output <- c(output, paste0(chars[last:n], collapse = ""))
  }
  paste0(output, collapse = "")
}

mask_phones_in_text <- function(input_text, mask_char) {
  chars <- strsplit(input_text, "", fixed = TRUE)[[1]]
  n <- length(chars)
  if (n == 0) {
    return(input_text)
  }

  output <- character(0)
  last <- 1
  i <- 1

  while (i <= n) {
    if (is_phone_start(chars[i])) {
      end <- i
      while (end <= n && is_phone_char(chars[end])) {
        end <- end + 1
      }
      end <- end - 1

      digit_count <- 0
      last_digit_index <- 0
      if (end >= i) {
        for (idx in i:end) {
          if (is_digit(chars[idx])) {
            digit_count <- digit_count + 1
            last_digit_index <- idx
          }
        }
      }

      if (last_digit_index > 0) {
        candidate_end <- last_digit_index
        if (digit_count >= 5) {
          candidate <- paste0(chars[i:candidate_end], collapse = "")
          if (last <= i - 1) {
            output <- c(output, paste0(chars[last:(i - 1)], collapse = ""))
          } else if (last == i) {
            output <- c(output, "")
          }
          output <- c(output, mask_phone_candidate(candidate, mask_char))
          last <- candidate_end + 1
          i <- candidate_end + 1
          next
        }
      }

      i <- end + 1
      next
    }
    i <- i + 1
  }

  if (last <= n) {
    output <- c(output, paste0(chars[last:n], collapse = ""))
  }
  paste0(output, collapse = "")
}

mask_local <- function(local, mask_char) {
  length <- nchar(local, type = "chars")
  if (length > 1) {
    first_char <- substr(local, 1, 1)
    return(paste0(first_char, paste(rep(mask_char, length - 1), collapse = "")))
  }
  mask_char
}

mask_phone_candidate <- function(candidate, mask_char) {
  chars <- strsplit(candidate, "", fixed = TRUE)[[1]]
  digit_count <- 0
  for (ch in chars) {
    if (is_digit(ch)) {
      digit_count <- digit_count + 1
    }
  }

  current_index <- 0
  result <- character(length(chars))
  for (idx in seq_along(chars)) {
    ch <- chars[idx]
    if (is_digit(ch)) {
      current_index <- current_index + 1
      if (digit_count > 4 && current_index <= digit_count - 4) {
        result[idx] <- mask_char
      } else {
        result[idx] <- ch
      }
    } else {
      result[idx] <- ch
    }
  }

  paste0(result, collapse = "")
}

is_local_char <- function(ch) {
  is_alpha(ch) || is_digit(ch) || ch %in% c(".", "_", "%", "+", "-")
}

is_domain_char <- function(ch) {
  is_alpha(ch) || is_digit(ch) || ch %in% c("-", ".")
}

is_valid_domain <- function(domain) {
  if (nchar(domain, type = "chars") == 0 || substr(domain, 1, 1) == "." ||
      substr(domain, nchar(domain, type = "chars"), nchar(domain, type = "chars")) == ".") {
    return(FALSE)
  }

  parts <- strsplit(domain, ".", fixed = TRUE)[[1]]
  if (length(parts) < 2) {
    return(FALSE)
  }

  for (part in parts) {
    if (nchar(part, type = "chars") == 0) {
      return(FALSE)
    }
    if (substr(part, 1, 1) == "-" || substr(part, nchar(part, type = "chars"), nchar(part, type = "chars")) == "-") {
      return(FALSE)
    }
    chars <- strsplit(part, "", fixed = TRUE)[[1]]
    for (ch in chars) {
      if (!(is_alnum(ch) || ch == "-")) {
        return(FALSE)
      }
    }
  }

  tld <- parts[length(parts)]
  if (nchar(tld, type = "chars") < 2) {
    return(FALSE)
  }
  tld_chars <- strsplit(tld, "", fixed = TRUE)[[1]]
  for (ch in tld_chars) {
    if (!is_alpha(ch)) {
      return(FALSE)
    }
  }

  TRUE
}

is_phone_start <- function(ch) {
  is_digit(ch) || ch %in% c("+", "(")
}

is_phone_char <- function(ch) {
  is_digit(ch) || ch %in% c(" ", "-", "(", ")", "+")
}

is_digit <- function(ch) {
  code <- utf8ToInt(ch)
  length(code) == 1 && code >= 48 && code <= 57
}

is_alpha <- function(ch) {
  code <- utf8ToInt(ch)
  length(code) == 1 && ((code >= 65 && code <= 90) || (code >= 97 && code <= 122))
}

is_alnum <- function(ch) {
  is_alpha(ch) || is_digit(ch)
}
