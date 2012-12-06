TRANSPAK_STATUS = YAML::load(File.open(File.join(Rails.root, "config", "transpak.yml")))
FORWARDAIR_STATUS = YAML::load(File.open(File.join(Rails.root, "config", "forwardair.yml")))