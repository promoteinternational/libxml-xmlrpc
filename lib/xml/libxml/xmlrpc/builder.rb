require 'base64'

module XML
    module XMLRPC
        #
        # Class to build XML-RPC responses and calls.
        #
        # Example:
        #
        #   XML::XMLRPC::Builder.foo(1,2,3) # generates xml for method call
        #                                   # 'foo' with arguments of int 1, 2
        #                                   # and 3
        #
        #   XML::XMLRPC::Builder.response(1,2,3) # builds a response with args
        #                                        # 1,2,3
        #
        #   # builds a fault response with faultCode 0 and faultString "Foo"
        #   XML::XMLRPC::Builder.fault_response(2, "Foo") 
        #
        #   # builds a call called 'fault_response'
        #   XML::XMLRPC::Builder.call('fault_response', 1, 2, 3)
        #
        # Notes:
        #  * To build a Base64 object, check out the XML::XMLRPC::Builder::Base64 class.
        #  * Date (and all other) objects must inherit directly from class
        #    Date or be the class themselves, DateTime is an example of direct
        #    inheritance of Date. Time (which inherits from Object) will NOT
        #    work.
        #  * All responses are encoded UTF-8. Be sure your strings, etc are
        #    UTF-8 before passing them into this module.
        #
        module Builder


            # toggles builder debugging
            def self.debug=(x)
                @debug = x 
            end

            # gets the debugging state
            def self.debug
                @debug
            end
            
            self.debug = false

            # Builds the appropriate XML for a methodCall.
            # 
            # Takes a methodname and a series of arguments.
            # 
            def self.call(methodname, *args)
                methodname = methodname.to_s

                output = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
                output += "<methodCall><methodName>#{methodname}</methodName>"
                output += Value.generate(*args)
                output += "</methodCall>"

                self.debug_output output

                return output
            end

            #
            # Builds a response. Takes a series of response arguments.
            #
            def self.response(*args)
                output = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
                output += "<methodResponse>"
                output += Value.generate(*args)
                output += "</methodResponse>"

                self.debug_output output

                return output
            end

            #
            # Builds a fault response. Takes a faultCode (integer) and a faultMessage (string).
            #
            def self.fault_response(faultCode, faultMessage)
                output = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
                output += "<methodResponse>"
                output += "<fault><value><struct>"
                output += "<member><name>faultCode</name><value><int>#{faultCode}</int></value></member>"
                output += "<member><name>faultString</name><value><string>#{faultMessage}</string></value></member>"
                output += "</struct></value></fault>"
                output += "</methodResponse>"

                self.debug_output output

                return output
            end

            #
            # Just calls #call, your method name will be the first argument and
            # will be passed to call properly.
            #
            def self.method_missing(*args)
                self.call(*args)
            end

            private  

            def self.debug_output(output)
                if @debug
                    $stderr.puts "Building:\n#{output}"
                end
            end
        end

        #
        # Thrown when Builder encounters an error.
        #
        class Builder::Error < Exception
        end

        #
        # Base64 type class. The 'Base64' module that comes with ruby does not
        # hold anything (it's not a class), and since our parser depends on
        # having the appropriate type to generate the right value clause, this
        # is required for Base64 transfers.
        # 
        class Builder::Base64

            #
            # Takes a string.
            #
            def initialize(str)
                @string = str
            end

            #
            # Encodes the encapsulated string as Base64.
            #
            def encode
                ::Base64.encode64(@string)
            end
        end

        #
        # Generates Values. This has several subclasses that map to
        # core types which I will not document.
        # 
        # RTFS.
        #

        module Builder::Value

            def self.generate(*args)
                output = "<params>"
                args.each do |x|
                    output += "<param>"
                    output += self.generate_value(x)
                    output += "</param>"
                end
                output += "</params>"

                return output
            end

            def self.generate_value(arg)
                output = "<value>"

                # try the superclass if the class doesn't work (this isn't
                # perfect but is better than nothing)
                if arg.class == Builder::Base64
                    output += Base64.generate(arg)
                elsif const_get(arg.class.to_s).respond_to? :generate
                    output += const_get(arg.class.to_s).generate(arg)
                elsif const_get(arg.class.superclass.to_s).respond_to? :generate
                    output += const_get(arg.class.superclass.to_s).generate(arg)
                else
                    raise Builder::Error, "Type '#{arg.class}' is not supported by XML-RPC"
                end

                output += "</value>"

                return output
            end

            module Base64
                def self.generate(arg)
                    "<base64>#{arg.encode}</base64>"
                end
            end

            module Integer
                def self.generate(arg)
                    "<int>#{arg}</int>"
                end
            end

            module Fixnum
                def self.generate(arg)
                    "<int>#{arg}</int>"
                end
            end

            module String
                def self.generate(arg)
                    "<string>#{arg}</string>"
                end
            end

            module Float
                def self.generate(arg)
                    "<double>#{arg}</double>"
                end
            end

            module Date
                def self.generate(arg)
                    "<dateTime.iso8601>" + arg.strftime("%Y%m%dT%T") + "</dateTime.iso8601>"
                end
            end

            module Array
                def self.generate(args)
                    output = "<array><data>"
                    args.each do |x|
                        output += Builder::Value.generate_value(x)
                    end
                    output += "</data></array>"

                    return output
                end
            end

            module Hash
                def self.generate(args)
                    output = "<struct>"
                    args.each_key do |key|
                        output += "<member>"
                        output += "<name>#{key}</name>"
                        output += Builder::Value.generate_value(args[key])
                        output += "</member>"
                    end
                    output += "</struct>"
                    return output
                end
            end

            module TrueClass
                def self.generate(arg)
                    "<boolean>1</boolean>"
                end
            end

            module FalseClass
                def self.generate(arg)
                    "<boolean>0</boolean>"
                end
            end

            module NilClass
                def self.generate(arg)
                    # nil is treated as false in our spec
                    FalseClass.generate(arg)
                end
            end
        end
    end
end
