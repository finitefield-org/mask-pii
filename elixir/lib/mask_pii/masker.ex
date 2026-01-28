defmodule MaskPII.Masker do
  @moduledoc """
  A configurable masker for common PII such as emails and phone numbers.
  """

  defstruct mask_email: false,
            mask_phone: false,
            mask_char: "*"

  @type t :: %__MODULE__{
          mask_email: boolean,
          mask_phone: boolean,
          mask_char: String.t()
        }

  @doc """
  Create a new masker with all masks disabled by default.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc """
  Enable email address masking.
  """
  @spec mask_emails(t()) :: t()
  def mask_emails(%__MODULE__{} = masker) do
    %__MODULE__{masker | mask_email: true}
  end

  @doc """
  Enable phone number masking.
  """
  @spec mask_phones(t()) :: t()
  def mask_phones(%__MODULE__{} = masker) do
    %__MODULE__{masker | mask_phone: true}
  end

  @doc """
  Set the character used for masking.
  """
  @spec with_mask_char(t(), String.t() | integer() | nil) :: t()
  def with_mask_char(%__MODULE__{} = masker, mask_char) do
    %__MODULE__{masker | mask_char: normalize_mask_char(mask_char)}
  end

  @doc """
  Process input text and mask enabled PII patterns.
  """
  @spec process(t(), String.t()) :: String.t()
  def process(%__MODULE__{} = masker, input) when is_binary(input) do
    if !masker.mask_email && !masker.mask_phone do
      input
    else
      result = input

      result =
        if masker.mask_email do
          mask_emails_in_text(result, masker.mask_char)
        else
          result
        end

      if masker.mask_phone do
        mask_phones_in_text(result, masker.mask_char)
      else
        result
      end
    end
  end

  defp normalize_mask_char(nil), do: "*"
  defp normalize_mask_char(<<>>), do: "*"
  defp normalize_mask_char(<<c::utf8, _rest::binary>>), do: <<c::utf8>>
  defp normalize_mask_char(c) when is_integer(c), do: <<c::utf8>>
  defp normalize_mask_char(other), do: other |> to_string() |> normalize_mask_char()

  defp mask_emails_in_text(input, mask_char) do
    len = byte_size(input)
    {acc, last, _} = mask_emails_loop(input, len, mask_char, 0, 0, [])
    tail = binary_part(input, last, len - last)
    IO.iodata_to_binary(Enum.reverse([tail | acc]))
  end

  defp mask_emails_loop(_input, len, _mask_char, i, last, acc) when i >= len do
    {acc, last, i}
  end

  defp mask_emails_loop(input, len, mask_char, i, last, acc) do
    if :binary.at(input, i) == ?@ do
      local_start = scan_local_start(input, i)
      local_end = i
      domain_start = i + 1
      domain_end = scan_domain_end(input, len, domain_start)

      if local_start < local_end && domain_start < domain_end do
        case find_valid_domain_end(input, domain_start, domain_end) do
          nil ->
            mask_emails_loop(input, len, mask_char, i + 1, last, acc)

          valid_end ->
            local = binary_part(input, local_start, local_end - local_start)
            domain = binary_part(input, domain_start, valid_end - domain_start)
            before = binary_part(input, last, local_start - last)
            masked_local = mask_local(local, mask_char)
            acc = [domain, "@", masked_local, before | acc]
            mask_emails_loop(input, len, mask_char, valid_end, valid_end, acc)
        end
      else
        mask_emails_loop(input, len, mask_char, i + 1, last, acc)
      end
    else
      mask_emails_loop(input, len, mask_char, i + 1, last, acc)
    end
  end

  defp scan_local_start(_input, 0), do: 0

  defp scan_local_start(input, i) do
    prev_index = i - 1

    if prev_index >= 0 && is_local_byte(:binary.at(input, prev_index)) do
      scan_local_start(input, prev_index)
    else
      i
    end
  end

  defp scan_domain_end(_input, len, i) when i >= len, do: len

  defp scan_domain_end(input, len, i) do
    if is_domain_byte(:binary.at(input, i)) do
      scan_domain_end(input, len, i + 1)
    else
      i
    end
  end

  defp find_valid_domain_end(_input, domain_start, candidate_end) when candidate_end <= domain_start,
    do: nil

  defp find_valid_domain_end(input, domain_start, candidate_end) do
    domain = binary_part(input, domain_start, candidate_end - domain_start)

    if valid_domain?(domain) do
      candidate_end
    else
      find_valid_domain_end(input, domain_start, candidate_end - 1)
    end
  end

  defp mask_phones_in_text(input, mask_char) do
    len = byte_size(input)
    {acc, last, _} = mask_phones_loop(input, len, mask_char, 0, 0, [])
    tail = binary_part(input, last, len - last)
    IO.iodata_to_binary(Enum.reverse([tail | acc]))
  end

  defp mask_phones_loop(_input, len, _mask_char, i, last, acc) when i >= len do
    {acc, last, i}
  end

  defp mask_phones_loop(input, len, mask_char, i, last, acc) do
    if is_phone_start(:binary.at(input, i)) do
      end_index = scan_phone_end(input, len, i)
      {digit_count, last_digit_index} = count_digits(input, i, end_index)

      if last_digit_index != nil && digit_count >= 5 do
        candidate_end = last_digit_index + 1
        candidate = binary_part(input, i, candidate_end - i)
        before = binary_part(input, last, i - last)
        masked = mask_phone_candidate(candidate, mask_char)
        acc = [masked, before | acc]
        mask_phones_loop(input, len, mask_char, candidate_end, candidate_end, acc)
      else
        mask_phones_loop(input, len, mask_char, end_index, last, acc)
      end
    else
      mask_phones_loop(input, len, mask_char, i + 1, last, acc)
    end
  end

  defp scan_phone_end(_input, len, i) when i >= len, do: len

  defp scan_phone_end(input, len, i) do
    if is_phone_char(:binary.at(input, i)) do
      scan_phone_end(input, len, i + 1)
    else
      i
    end
  end

  defp count_digits(input, start_index, end_index) do
    count_digits(input, start_index, end_index, 0, nil)
  end

  defp count_digits(_input, i, end_index, count, last_digit_index) when i >= end_index do
    {count, last_digit_index}
  end

  defp count_digits(input, i, end_index, count, last_digit_index) do
    byte = :binary.at(input, i)

    if digit_byte?(byte) do
      count_digits(input, i + 1, end_index, count + 1, i)
    else
      count_digits(input, i + 1, end_index, count, last_digit_index)
    end
  end

  defp mask_local(local, mask_char) do
    len = byte_size(local)

    if len > 1 do
      first = binary_part(local, 0, 1)
      first <> String.duplicate(mask_char, len - 1)
    else
      mask_char
    end
  end

  defp mask_phone_candidate(candidate, mask_char) do
    digit_count = count_digits_in_binary(candidate)

    {acc, _} =
      for <<byte <- candidate>>, reduce: {[], 0} do
        {parts, index} ->
          if digit_byte?(byte) do
            next_index = index + 1

            if digit_count > 4 && next_index <= digit_count - 4 do
              {[mask_char | parts], next_index}
            else
              {[<<byte>> | parts], next_index}
            end
          else
            {[<<byte>> | parts], index}
          end
      end

    IO.iodata_to_binary(Enum.reverse(acc))
  end

  defp count_digits_in_binary(binary) do
    for <<byte <- binary>>, reduce: 0 do
      acc -> if digit_byte?(byte), do: acc + 1, else: acc
    end
  end

  defp is_local_byte(byte) do
    byte in ?a..?z or byte in ?A..?Z or byte in ?0..?9 or byte in [?. , ?_, ?%, ?+, ?-]
  end

  defp is_domain_byte(byte) do
    byte in ?a..?z or byte in ?A..?Z or byte in ?0..?9 or byte in [?-, ?.]
  end

  defp valid_domain?(domain) do
    size = byte_size(domain)

    if size == 0 do
      false
    else
      first = :binary.at(domain, 0)
      last = :binary.at(domain, size - 1)

      if first == ?. || last == ?. do
        false
      else
        parts = String.split(domain, ".", trim: false)

        if length(parts) < 2 do
          false
        else
          parts_valid? = Enum.all?(parts, &valid_domain_label?/1)

          if parts_valid? do
            tld = List.last(parts)
            valid_tld?(tld)
          else
            false
          end
        end
      end
    end
  end

  defp valid_domain_label?(label) do
    size = byte_size(label)

    if size == 0 do
      false
    else
      first = :binary.at(label, 0)
      last = :binary.at(label, size - 1)

      if first == ?- || last == ?- do
        false
      else
        for <<byte <- label>>, reduce: true do
          acc -> acc && (byte in ?a..?z or byte in ?A..?Z or byte in ?0..?9 or byte == ?-)
        end
      end
    end
  end

  defp valid_tld?(tld) do
    size = byte_size(tld)

    if size < 2 do
      false
    else
      for <<byte <- tld>>, reduce: true do
        acc -> acc && (byte in ?a..?z or byte in ?A..?Z)
      end
    end
  end

  defp is_phone_start(byte), do: digit_byte?(byte) || byte in [?+, ?(]

  defp is_phone_char(byte), do: digit_byte?(byte) || byte in [?\s, ?-, ?(, ?), ?+]

  defp digit_byte?(byte), do: byte in ?0..?9
end
