package org.finitefield.maskpii

import spock.lang.Specification
import spock.lang.Unroll

class MaskerSpec extends Specification {
    @Unroll
    def "email masking: #input"() {
        given:
        def masker = new Masker().maskEmails()

        expect:
        masker.process(input) == expected

        where:
        input | expected
        'alice@example.com' | 'a****@example.com'
        'a@b.com' | '*@b.com'
        'ab@example.com' | 'a*@example.com'
        'a.b+c_d@example.co.jp' | 'a******@example.co.jp'
        'Contact: alice@example.com.' | 'Contact: a****@example.com.'
        'alice@example.com and bob@example.org' | 'a****@example.com and b**@example.org'
        'alice@example' | 'alice@example'
        'alice@localhost' | 'alice@localhost'
        'alice@@example.com' | 'alice@@example.com'
        'first.last+tag@sub.domain.com' | 'f*************@sub.domain.com'
    }

    @Unroll
    def "phone masking: #input"() {
        given:
        def masker = new Masker().maskPhones()

        expect:
        masker.process(input) == expected

        where:
        input | expected
        '090-1234-5678' | '***-****-5678'
        'Call (555) 123-4567' | 'Call (***) ***-4567'
        'Intl: +81 3 1234 5678' | 'Intl: +** * **** 5678'
        '+1 (800) 123-4567' | '+* (***) ***-4567'
        '1234' | '1234'
        '12345' | '*2345'
        '12-3456' | '**-3456'
        'Tel: 090-1234-5678 ext. 99' | 'Tel: ***-****-5678 ext. 99'
        'Numbers: 111-2222 and 333-4444' | 'Numbers: ***-2222 and ***-4444'
        'abcdef' | 'abcdef'
        '+' | '+'
        '(12) 345 678' | '(**) **5 678'
    }

    @Unroll
    def "combined masking: #input"() {
        given:
        def masker = new Masker().maskEmails().maskPhones()

        expect:
        masker.process(input) == expected

        where:
        input | expected
        'Contact: alice@example.com or 090-1234-5678.' | 'Contact: a****@example.com or ***-****-5678.'
        'Email bob@example.org, phone +1 (800) 123-4567' | 'Email b**@example.org, phone +* (***) ***-4567'
    }

    def 'custom mask character'() {
        given:
        def masker = new Masker().maskEmails().maskPhones().withMaskChar('#')

        expect:
        masker.process('alice@example.com') == 'a####@example.com'
        masker.process('090-1234-5678') == '###-####-5678'
        masker.process('Contact: alice@example.com or 090-1234-5678.') ==
            'Contact: a####@example.com or ###-####-5678.'
    }

    def 'masker configuration behavior'() {
        expect:
        new Masker().process('Contact: alice@example.com or 090-1234-5678.') ==
            'Contact: alice@example.com or 090-1234-5678.'
        new Masker().maskEmails().process('alice@example.com 090-1234-5678') ==
            'a****@example.com 090-1234-5678'
        new Masker().maskPhones().process('alice@example.com 090-1234-5678') ==
            'alice@example.com ***-****-5678'
        new Masker().maskEmails().maskPhones().process('alice@example.com 090-1234-5678') ==
            'a****@example.com ***-****-5678'
    }
}
