require 'test/unit'
require 'xml/libxml/xmlrpc/parser'

class TestParserBad < Test::Unit::TestCase
    def test_01_empty_string
        assert_raise XML::XMLRPC::ParserError do
            XML::XMLRPC::Parser.new('')
        end
    end
end
