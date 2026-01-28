\name{Masker}
\alias{Masker}
\title{Create a configurable masker for emails and phone numbers}
\description{Create a masker that can selectively mask emails, phone numbers, or both.}
\usage{
Masker()
}
\value{A masker object with chainable methods.}
\details{The masker exposes \code{mask_emails()}, \code{mask_phones()},
\code{with_mask_char()}, and \code{process()} methods for configuration and
processing.}
\examples{
masker <- Masker()
result <- masker$mask_emails()$mask_phones()$process(
  "Contact: alice@example.com or 090-1234-5678."
)
print(result)
}
