import std.stdio : writeln;
import mask_pii : Masker;

void main() {
    auto masker = Masker()
        .maskEmails()
        .maskPhones()
        .withMaskChar('#');

    auto inputText = "Contact: alice@example.com or 090-1234-5678.";
    auto outputText = masker.process(inputText);

    writeln(outputText);
}
