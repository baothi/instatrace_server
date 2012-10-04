# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "meta_where"
  s.version = "1.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ernie Miller"]
  s.date = "2011-02-27"
  s.description = "\n      MetaWhere offers the ability to call any Arel predicate methods\n      (with a few convenient aliases) on your Model's attributes instead\n      of the ones normally offered by ActiveRecord's hash parameters. It also\n      adds convenient syntax for order clauses, smarter mapping of nested hash\n      conditions, and a debug_sql method to see the real SQL your code is\n      generating without running it against the database. If you like the new\n      AR 3.0 query interface, you'll love it with MetaWhere.\n    "
  s.email = ["ernie@metautonomo.us"]
  s.extra_rdoc_files = ["LICENSE", "README.rdoc"]
  s.files = ["LICENSE", "README.rdoc"]
  s.homepage = "http://metautonomo.us/projects/metawhere"
  s.post_install_message = "\n*** Thanks for installing MetaWhere! ***\nBe sure to check out http://metautonomo.us/projects/metawhere/ for a\nwalkthrough of MetaWhere's features, and click the donate button if\nyou're feeling especially appreciative. It'd help me justify this\n\"open source\" stuff to my lovely wife. :)\n\n"
  s.require_paths = ["lib"]
  s.rubyforge_project = "meta_where"
  s.rubygems_version = "1.8.24"
  s.summary = "ActiveRecord 3 query syntax on steroids."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>, ["~> 3.0.0"])
      s.add_runtime_dependency(%q<activesupport>, ["~> 3.0.0"])
      s.add_runtime_dependency(%q<arel>, ["~> 2.0.7"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<sqlite3>, ["~> 1.3.3"])
    else
      s.add_dependency(%q<activerecord>, ["~> 3.0.0"])
      s.add_dependency(%q<activesupport>, ["~> 3.0.0"])
      s.add_dependency(%q<arel>, ["~> 2.0.7"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<sqlite3>, ["~> 1.3.3"])
    end
  else
    s.add_dependency(%q<activerecord>, ["~> 3.0.0"])
    s.add_dependency(%q<activesupport>, ["~> 3.0.0"])
    s.add_dependency(%q<arel>, ["~> 2.0.7"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<sqlite3>, ["~> 1.3.3"])
  end
end
