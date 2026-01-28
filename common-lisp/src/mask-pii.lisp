(defpackage :mask-pii
  (:use :cl)
  (:export :masker
           :new-masker
           :mask-emails
           :mask-phones
           :with-mask-char
           :process))

(in-package :mask-pii)

(defstruct (masker (:constructor %make-masker))
  "Configuration for masking emails and phone numbers."
  (email-enabled nil :type boolean)
  (phone-enabled nil :type boolean)
  (mask-char #\* :type character))

(defun new-masker ()
  "Create a new masker with all masks disabled."
  (%make-masker :email-enabled nil :phone-enabled nil :mask-char #\*))

(defun mask-emails (masker)
  "Enable email address masking and return the masker."
  (setf (masker-email-enabled masker) t)
  masker)

(defun mask-phones (masker)
  "Enable phone number masking and return the masker."
  (setf (masker-phone-enabled masker) t)
  masker)

(defun with-mask-char (masker mask-char)
  "Set the character used for masking and return the masker.

The mask character may be a character or a string; when a string is provided,
its first character is used. NIL or an empty string resets to '*'."
  (setf (masker-mask-char masker) (sanitize-mask-char mask-char))
  masker)

(defun process (masker input)
  "Process input text and mask enabled PII patterns."
  (let* ((text (if input (copy-seq (string input)) ""))
         (mask-char (sanitize-mask-char (masker-mask-char masker))))
    (cond
      ((and (not (masker-email-enabled masker))
            (not (masker-phone-enabled masker)))
       text)
      (t
       (let ((after-emails (if (masker-email-enabled masker)
                               (mask-emails-in-text text mask-char)
                               text)))
         (if (masker-phone-enabled masker)
             (mask-phones-in-text after-emails mask-char)
             after-emails))))))

(defun sanitize-mask-char (mask-char)
  (cond
    ((characterp mask-char)
     (if (char= mask-char #\Null) #\* mask-char))
    ((stringp mask-char)
     (if (> (length mask-char) 0)
         (let ((first (char mask-char 0)))
           (if (char= first #\Null) #\* first))
         #\*))
    (t #\*)))

(defun mask-emails-in-text (text mask-char)
  (let* ((len (length text))
         (last 0))
    (with-output-to-string (out)
      (loop for i from 0 below len do
        (when (char= (aref text i) #\@)
          (let* ((local-start (scan-left-local text (1- i)))
                 (local-end i)
                 (domain-start (1+ i))
                 (domain-end (scan-right-domain text len domain-start)))
            (when (and (< local-start local-end)
                       (< domain-start domain-end))
              (let ((matched-domain-end
                      (find-valid-domain text domain-start domain-end)))
                (when matched-domain-end
                  (write-string (subseq text last local-start) out)
                  (write-string (mask-local (subseq text local-start local-end)
                                            mask-char)
                                out)
                  (write-char #\@ out)
                  (write-string (subseq text domain-start matched-domain-end) out)
                  (setf last matched-domain-end)
                  (setf i (1- matched-domain-end)))))))
      (when (< last len)
        (write-string (subseq text last len) out)))))

(defun mask-phones-in-text (text mask-char)
  (let* ((len (length text))
         (last 0))
    (with-output-to-string (out)
      (loop for i from 0 below len do
        (when (phone-start-char-p (aref text i))
          (let* ((end-index (scan-right-phone text len i))
                 (digit-info (scan-phone-digits text i end-index))
                 (digit-count (first digit-info))
                 (last-digit (second digit-info)))
            (cond
              ((and last-digit (>= digit-count 5))
               (let* ((candidate-end (1+ last-digit))
                      (candidate (subseq text i candidate-end)))
                 (write-string (subseq text last i) out)
                 (write-string (mask-phone-candidate candidate mask-char) out)
                 (setf last candidate-end)
                 (setf i (1- candidate-end))))
              (t
               (setf i (1- end-index)))))))
      (when (< last len)
        (write-string (subseq text last len) out)))))

(defun mask-local (local mask-char)
  (if (> (length local) 1)
      (concatenate 'string
                   (string (char local 0))
                   (make-string (1- (length local)) :initial-element mask-char))
      (string mask-char)))

(defun mask-phone-candidate (candidate mask-char)
  (let* ((digit-count (count-if #'ascii-digit-p candidate))
         (mask-until (- digit-count 4))
         (digit-index 0))
    (if (<= digit-count 4)
        candidate
        (with-output-to-string (out)
          (loop for ch across candidate do
            (if (ascii-digit-p ch)
                (progn
                  (incf digit-index)
                  (if (<= digit-index mask-until)
                      (write-char mask-char out)
                      (write-char ch out)))
                (write-char ch out)))))))

(defun scan-left-local (text idx)
  (if (< idx 0)
      0
      (loop for i from idx downto 0
            while (local-char-p (aref text i))
            finally (return (1+ i)))))

(defun scan-right-domain (text len idx)
  (loop for i from idx below len
        while (domain-char-p (aref text i))
        finally (return i)))

(defun scan-right-phone (text len idx)
  (loop for i from idx below len
        while (phone-char-p (aref text i))
        finally (return i)))

(defun scan-phone-digits (text start end)
  (let ((count 0)
        (last-digit nil))
    (loop for i from start below end do
      (when (ascii-digit-p (aref text i))
        (incf count)
        (setf last-digit i)))
    (list count last-digit)))

(defun find-valid-domain (text start end)
  (loop for candidate-end from end downto (1+ start)
        for domain = (subseq text start candidate-end)
        when (valid-domain-p domain)
          do (return candidate-end)))

(defun valid-domain-p (domain)
  (cond
    ((zerop (length domain)) nil)
    ((or (char= (char domain 0) #\.)
         (char= (char domain (1- (length domain))) #\.))
     nil)
    (t
     (let ((parts (split-on-char domain #\.)))
       (and (>= (length parts) 2)
            (every #'valid-domain-label-p parts)
            (valid-tld-p (car (last parts))))))))

(defun valid-domain-label-p (label)
  (and (> (length label) 0)
       (not (char= (char label 0) #\-))
       (not (char= (char label (1- (length label))) #\-))
       (loop for ch across label
             always (or (ascii-alnum-p ch) (char= ch #\-)))))

(defun valid-tld-p (tld)
  (and (>= (length tld) 2)
       (loop for ch across tld
             always (ascii-alpha-p ch))))

(defun split-on-char (text delimiter)
  (let ((parts '())
        (start 0)
        (len (length text)))
    (loop for i from 0 below len do
      (when (char= (aref text i) delimiter)
        (push (subseq text start i) parts)
        (setf start (1+ i))))
    (push (subseq text start len) parts)
    (nreverse parts)))

(defun local-char-p (ch)
  (or (ascii-alnum-p ch)
      (member ch '(#\. #\_ #\% #\+ #\-) :test #'char=)))

(defun domain-char-p (ch)
  (or (ascii-alnum-p ch)
      (member ch '(#\- #\.) :test #'char=)))

(defun phone-start-char-p (ch)
  (or (ascii-digit-p ch) (char= ch #\+) (char= ch #\()))

(defun phone-char-p (ch)
  (or (ascii-digit-p ch)
      (member ch '(#\Space #\- #\( #\) #\+) :test #'char=)))

(defun ascii-digit-p (ch)
  (and (char>= ch #\0) (char<= ch #\9)))

(defun ascii-alpha-p (ch)
  (or (and (char>= ch #\A) (char<= ch #\Z))
      (and (char>= ch #\a) (char<= ch #\z))))

(defun ascii-alnum-p (ch)
  (or (ascii-alpha-p ch) (ascii-digit-p ch)))
