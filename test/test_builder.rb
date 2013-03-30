require 'test/unit'
require 'xml/libxml/xmlrpc/builder'
require 'xml/libxml/xmlrpc/parser'

class TestBuilder < Test::Unit::TestCase

    def setup
        @class = XML::XMLRPC::Builder
    end

    def test_debug

        assert(!@class.instance_variable_get("@debug"))

        assert_nothing_raised do
            @class.debug = true
        end

        assert(@class.instance_variable_get("@debug")) 

        assert_nothing_raised do
            @class.debug = false
        end
    end


    def test_call
        # ugh. these sure are ugly.
        assert_equal(@class.foo,
            "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<methodCall><methodName>foo</methodName><params></params></methodCall>")
        assert_equal(@class.bar,
            "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<methodCall><methodName>bar</methodName><params></params></methodCall>")
        assert_equal(@class.foo(1), 
            "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<methodCall><methodName>foo</methodName><params><param><value><int>1</int></value></param></params></methodCall>")
        assert_equal(@class.foo(1,2,3), 
            "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<methodCall><methodName>foo</methodName><params><param><value><int>1</int></value></param><param><value><int>2</int></value></param><param><value><int>3</int></value></param></params></methodCall>")
        assert_equal(@class.foo(nil), 
            "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<methodCall><methodName>foo</methodName><params><param><value><boolean>0</boolean></value></param></params></methodCall>")
        assert_equal(@class.foo(Date.civil(1978, 4, 6)), 
             "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<methodCall><methodName>foo</methodName><params><param><value><dateTime.iso8601>19780406T00:00:00</dateTime.iso8601></value></param></params></methodCall>")
        assert_equal(@class.foo([1,2,3]), 
            "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<methodCall><methodName>foo</methodName><params><param><value><array><data><value><int>1</int></value><value><int>2</int></value><value><int>3</int></value></data></array></value></param></params></methodCall>")
        assert_equal(@class.foo(XML::XMLRPC::Builder::Base64.new("foo")),
             "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<methodCall><methodName>foo</methodName><params><param><value><base64>Zm9v\n</base64></value></param></params></methodCall>")

        # parse test. Our parser should be able to parse what we generate.
       
        xml = XML::XMLRPC::Parser.new(@class.foo([1,2,3], { :Bar => 1, :Foo => 2 }, XML::XMLRPC::Builder::Base64.new("foo")))
        assert_equal(xml[0], [1,2,3])
        assert_equal(xml[1], { :Bar => 1, :Foo => 2})
        assert_equal(xml[2], "foo")
        assert_equal("foo", xml.method)

        # response/fault call test
        
        xml = XML::XMLRPC::Parser.new(@class.call('response', 1,2,3))
        assert_equal(xml[0], 1)
        assert_equal(xml[1], 2)
        assert_equal(xml[2], 3) 
        assert_equal("response", xml.method)


        xml = XML::XMLRPC::Parser.new(@class.call('fault_response', 1,2,3))
        assert_equal(xml[0], 1)
        assert_equal(xml[1], 2)
        assert_equal(xml[2], 3) 
        assert_equal("fault_response", xml.method)
    end

    def test_response
        assert_equal(@class.response, 
            "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<methodResponse><params></params></methodResponse>")
        assert_equal(@class.response(nil), 
            "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<methodResponse><params><param><value><boolean>0</boolean></value></param></params></methodResponse>")
        assert_equal(@class.fault_response(0, "foo"), 
            "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n<methodResponse><fault><value><struct><member><name>faultCode</name><value><int>0</int></value></member><member><name>faultString</name><value><string>foo</string></value></member></struct></value></fault></methodResponse>")

        # parser test
        
        xml = XML::XMLRPC::Parser.new(@class.response(1,2,3))
        assert_equal(xml[0], 1)
        assert_equal(xml[1], 2)
        assert_equal(xml[2], 3) 
        assert_equal(xml.method, nil)

        # test faults
        assert_raise XML::XMLRPC::RemoteCallError do 
            xml = XML::XMLRPC::Parser.new(@class.fault_response(0, "Foo"))
        end

        e = nil

        assert_nothing_raised do
            begin
                xml = XML::XMLRPC::Parser.new(@class.fault_response(0, "Foo"))
            rescue XML::XMLRPC::RemoteCallError => error
                e = error
            end
        end

        assert_instance_of(XML::XMLRPC::RemoteCallError, e)
        assert_equal(e.message, "0: Foo")
    end
end
