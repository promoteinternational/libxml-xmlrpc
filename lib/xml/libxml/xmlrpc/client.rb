require 'xml/libxml/xmlrpc/parser'
require 'xml/libxml/xmlrpc/builder'

module XML
    module XMLRPC
        #
        # Client is an easy-to-use XML-RPC method call and response mechanism.
        #
        # It will not handle redirection.
        #
        class Client

            # set the debug state
            def self.debug=(x)
                @debug = x
            end

            # get the debug state
            def self.debug
                @debug
            end

            #
            # Given an unused Net::HTTP object and a relative URL, it will post
            # the XML-RPC information to this form after calling a method with
            # ruby types.
            # 
            # See XML::XMLRPC::Builder for caveats related to Base64 handling.
            #
            def initialize(http, url)
                @http = http
                @url  = url
            end

            #
            # See #call.
            # 
            def method_missing(*args)
                self.call(*args)
            end

            #
            # Call and recieve the response. Returns a XML::XMLRPC::Parser object.
            #
            # Will throw an XML::XMLRPC::RemoteCallError if the call returns a
            # fault response.
            #
            def call(methodName, *args)
                XML::XMLRPC::Builder.debug = self.class.debug
                XML::XMLRPC::Parser.debug = self.class.debug

                res = @http.post(@url, XML::XMLRPC::Builder.call(methodName, *args), { "Content-type" => 'text/xml' })
                res_args = XML::XMLRPC::Parser.new(res.body)
                return res_args
            end
        end
    end
end
