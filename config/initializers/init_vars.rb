COMMON = YAML::load(File.open(File.join(Rails.root, "config", "common.yml")))
TRANSPAK = YAML::load(File.open(File.join(Rails.root, "config", "transpak.yml")))
FORWARDAIR = YAML::load(File.open(File.join(Rails.root, "config", "forwardair.yml")))
DESCARTES_CARRIER = YAML::load(File.open(File.join(Rails.root, "config", "descartes.yml")))
COUNTRY_CODE = YAML::load(File.open(File.join(Rails.root, "config", "countrycode.yml")))
EMAIL_NOTIFY_POST_SHIPMENT_API = "bob@instatrace.com"
