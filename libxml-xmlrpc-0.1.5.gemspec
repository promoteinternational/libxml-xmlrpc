# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "libxml-xmlrpc"
  s.version = "0.1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Erik Hollensbe"]
  s.date = "2008-11-02"
  s.email = "erik@hollensbe.org"
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0")
  s.rubyforge_project = "libxml-tools"
  s.rubygems_version = "2.0.0"
  s.summary = "Provides a alternative and faster XML-RPC layer through libxml's parsing framework"

  if s.respond_to? :specification_version then
    s.specification_version = 1

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<libxml-ruby>, ["> 0.0.0"])
    else
      s.add_dependency(%q<libxml-ruby>, ["> 0.0.0"])
    end
  else
    s.add_dependency(%q<libxml-ruby>, ["> 0.0.0"])
  end
end
