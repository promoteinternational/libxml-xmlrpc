require 'test/unit'
require 'xml/libxml/xmlrpc/parser'
require 'stringio'

class TestParserGood < Test::Unit::TestCase

    def setup
        @libxml_class = Object.const_defined?("LibXML") ? LibXML::XML : XML
    end

    def test_constructor
        assert_raise XML::XMLRPC::ParserError do
            XML::XMLRPC::Parser.new(nil)
        end

        assert_nothing_raised do 
            XML::XMLRPC::Parser.new(File.open("test/data/big_call.xml"))
        end

        # should raise a LibXML error because there's nothing to parse
        # XXX libxml no likey empty string.
        assert_raise @libxml_class::Parser::ParseError do
            XML::XMLRPC::Parser.new("asdf")
        end
    end

    def test_debug
        assert(!XML::XMLRPC::Parser.debug)

        assert_nothing_raised do
            XML::XMLRPC::Parser.debug = true
        end

        assert(XML::XMLRPC::Parser.debug)

        assert_nothing_raised do
            XML::XMLRPC::Parser.debug = false
        end
    end

    def test_datatypes
        xml = nil

        assert_nothing_raised do
            xml = XML::XMLRPC::Parser.new(File.open("test/data/big_call.xml"))
        end

        # primitives
        
        assert_equal(41,    xml[0])
        assert_equal("41",  xml[1])
        assert_equal(true,  xml[2])
        assert_equal(false, xml[3])
        assert_equal(1.23,  xml[4])

        # DateTime
        assert_kind_of(DateTime, xml[5])
        assert_equal("1998-07-17T14:08:55+00:00", xml[5].to_s)

        assert_equal("monkeys", xml[6]) # base64

        assert_kind_of(Array, xml[7])
        assert_equal([xml[6], xml[5]], xml[7])

        assert_kind_of(Hash, xml[8])
        assert_equal({ :Monkeys => [xml[6], xml[5]], :Poo => xml[5]}, xml[8])

        assert_equal("examples.getStateName", xml.method)
    end

    def test_response
        xml = nil

        assert_raise XML::XMLRPC::RemoteCallError do
            xml = XML::XMLRPC::Parser.new(File.open("test/data/fail_response.xml"))
        end

        # ensure the failure message is getting sent properly
        e = nil
        begin
            xml = XML::XMLRPC::Parser.new(File.open("test/data/fail_response.xml"))
        rescue XML::XMLRPC::RemoteCallError => error
            e = error
        end

        assert_equal("4: Too many parameters.", e.message)

        assert_nothing_raised do
            xml = XML::XMLRPC::Parser.new(File.open("test/data/good_response.xml"))
        end

        assert_equal("South Dakota", xml[0])
    end

    def test_functionality
        xml = nil
        assert_nothing_raised do
            xml = XML::XMLRPC::Parser.new(File.open("test/data/big_call.xml"))
        end

        # Enumerable functionality 
        xml.each_with_index do |x, i|
            case i
            when 0
                assert_equal(41, x)
            when 1
                assert_equal("41", x)
            when 2
                assert_equal(true, x)
            when 3
                assert_equal(false, x)
            when 4
                assert_equal(1.23, x)
            end
            # that should be plenty.
        end

        assert(xml.include?(41))
    end

    def test_recursion
        xml = nil
        assert_nothing_raised do
            xml = XML::XMLRPC::Parser.new(File.open("test/data/recursion_test.xml"))
        end

        assert_equal(
            { 
                :Poo     => [{
                    :Poo     => ["monkeys", "19980717T14:08:55"],
                    :Monkeys => ["monkeys", "19980717T14:08:55"]
                }], 
                :Monkeys => ["monkeys", "19980717T14:08:55"]
            }, 
            xml[0]
        )
    end
end
