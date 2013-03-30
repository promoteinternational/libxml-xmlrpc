begin
    require 'rubygems'
    gem 'libxml-ruby'
rescue Exception => e
end

require 'xml/libxml'
require 'base64'
require 'date'
require 'stringio'

module XML::XMLRPC
    class RemoteCallError < Exception
    end
    class ParserError < Exception
    end

    #
    # Spec-compliant XML-RPC parser. Converts XML-RPC types to native Ruby
    # types.
    #
    # _Overview_:
    #   <?xml version="1.0"?>
    #     <methodResponse>
    #         <params>
    #             <param>
    #                 <value><string>South Dakota</string></value>
    #             </param>
    #         </params>
    #     </methodResponse> 
    #
    #   xml = XML::XMLRPC::Parser.new(IO, String, or StringIO object)
    #   xml[0] == "South Dakota"
    #
    # Notes:
    #  * Structs and Arrays are Hashes and Arrays respectively.
    #  * Base64 is auto-decoded.
    #  * Any interpreter-level (as opposed to syntax-level or exception
    #    handling) crash you see in ruby is the fault of libxml, not this code.
    #  * In a case where you're parsing a methodCall request, the method
    #    attribute will have data. In the case where you parse a response, method
    #    will be nil.
    #
    class Parser

        include Enumerable

        # set the debugging state
        def self.debug=(x)
            @debug = x
        end

        # get the debugging state
        def self.debug
            @debug
        end

        self.debug = false

        attr_reader :params
        attr_reader :method

        #
        # Takes a String or IO object, which contains a response or call.
        # 
        # Parses the document immediately.
        # 
        def initialize(io)
            @string = ""

            if io.kind_of? String
                @string = io
            elsif io.kind_of? IO or io.kind_of? StringIO # stupid StringIO
                @string = io.read
            else
                raise ParserError, "Argument to new must be String or IO"
            end

            if self.class.debug
                $stderr.puts "Parsing:\n#{@string}";
            end

            @params = []
            @method = nil
            self.parse!

            @params.freeze
            @method.freeze
        end

        #
        # Parses the document. Should not be required -- Parser#new already
        # does this for you.
        #
        def parse!

            if @string.empty?
                raise ParserError, 
                    "String is empty - libxml-ruby would normally crash your program here."
            end

            if Object.const_defined?("LibXML")
                klass = LibXML::XML
            else
                klass = XML
            end


            document = klass::Parser.string(@string).parse
            node = document.root
            case node.name
            when "methodCall"
                @method, @params = Parser::Call.parse(node)
            when "methodResponse"
                @params = Parser::Response.parse(node)
            else
                raise ParserError, "XMLRPC is invalid - no call or response"
            end
        end

        #
        # Obtain param x, where x is an integer.
        # 
        # Same as:
        # 
        #   xml.params[x]
        #
        def [](x)
            @params[x]
        end

        #
        # Iterate over each parameter.
        #

        def each
            @params.each do |x|
                yield x
            end
        end
    end

    #
    # Parse a methodCall.
    # 

    module Parser::Call
        def self.parse(node)
            method = node.find('/methodCall/methodName')
            methodname = "unknown"
            if method and method.to_a[0]
                content = method.to_a[0].content
                methodname = content
            end

            values = node.find('/methodCall/params/param/value')

            parsed_params = Parser::ValueParser.parse(values)

            return methodname, parsed_params
        end
    end

    #
    # Parse a methodResponse
    #

    class Parser::Response
        def self.parse(node)
            node.each_child do |child_node|
                case child_node.name.downcase
                when 'fault'
                    # RPC call has returned an error - find the fault and GTFO
                    value = Parser::ValueParser.parse(node.find('/methodResponse/fault/value'))
                    raise RemoteCallError, value.to_a[0][:faultCode].to_s + ": " + value[0][:faultString]
                when 'params'
                    return Parser::ValueParser.parse(node.find('/methodResponse/params/param/value'))
                end
            end
        end
    end

    #
    # Parse values from a XML::Node::Set or Array of XML::Node objects.
    #
    # May be called recursively by ValueParser::Array or ValueParser::Struct.
    # 

    module Parser::ValueParser
        def self.parse(values)
            parsed_params = []

            values.each do |param_value_node|
                value = nil
                if param_value_node
                    param_value_node.each_child do |type|
                        value = case type.name.downcase
                                when /^(?:i4|int)$/
                                    type.content.strip.to_i
                                when 'string'
                                    type.content
                                when 'boolean'
                                    if type.content.strip.to_i == 1
                                        true
                                    else
                                        false
                                    end
                                when 'double'
                                    type.content.strip.to_f
                                when 'datetime.iso8601'
                                    # Looks like this: 19980717T14:08:55
                                    DateTime.strptime(type.content.strip, "%Y%m%dT%T")
                                when 'base64'
                                    Base64.decode64(type.content.strip)
                                when 'struct'
                                    Parser::ValueParser::Struct.parse(type)
                                when 'array'
                                    Parser::ValueParser::Array.parse(type)
                                end

                        break if value
                    end
                end
                parsed_params.push value
            end

            return parsed_params
        end
    end

    #
    # Parse a 'struct' type.
    #

    module Parser::ValueParser::Struct
        def self.parse(node)
            # convert it to a hash with symbols as keys first.

            hash = { }

            node.each_child do |child_node|
                if child_node.name == "member" 
                    name = nil
                    value = nil 

                    child_node.each_child do |member_node|
                        if member_node.name == "name"
                            name = member_node.content.strip.to_sym
                            if value
                                hash[name] = value
                                break
                            end
                        elsif member_node.name == "value"
                            value = Parser::ValueParser.parse([member_node])[0]
                            if name
                                hash[name] = value
                                break
                            end
                        end
                    end
                end
            end 

            return hash
        end
    end

    #
    # Parse an 'array' type.
    # 

    module Parser::ValueParser::Array
        def self.parse(node)

            value = [] 

            node.each_child do |child_node|
                if child_node.name == "data"
                    value_nodes = []
                    child_node.each_child do |value_node|
                        if value_node.name == "value"
                            value_nodes.push value_node
                        end
                    end

                    value = Parser::ValueParser.parse(value_nodes)
                    break # yes, first hit is last hit, so says the stay-puff't spec.
                end
            end

            return value
        end
    end
end # fin.
