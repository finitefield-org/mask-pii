@Grab('org.finitefield:mask-pii:0.2.0')
import org.finitefield.maskpii.Masker

def masker = new Masker()
    .maskEmails()
    .maskPhones()
    .withMaskChar('#')

def inputText = 'Contact: alice@example.com or 090-1234-5678.'
println(masker.process(inputText))
