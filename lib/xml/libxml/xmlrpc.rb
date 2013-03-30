begin
    require 'rubygems'
    gem 'libxml-ruby'
    require 'xml/libxml'
rescue Exception => e
end

require 'xml/libxml/xmlrpc/client'
require 'xml/libxml/xmlrpc/parser'
require 'xml/libxml/xmlrpc/builder'

module XML
    #
    # XML::XMLRPC -- LibXML interface to XML-RPC
    # 
    # Right now, look at XML::XMLRPC::Parser, XML::XMLRPC::Builder
    # and XML::XMLRPC::Client for docs
    #
    # Author:: Erik Hollensbe <erik@hollensbe.org>
    #

    module XMLRPC
        VERSION = "0.1.5"
    end
end
