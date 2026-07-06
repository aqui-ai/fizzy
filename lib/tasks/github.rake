namespace :github do
  desc "Import aqui-fizzy-bridge issue->card mappings. Args: external_account_id, path to JSON file"
  task :import_bridge_mappings, [ :external_account_id, :path ] => :environment do |_task, args|
    account = Account.find_by!(external_account_id: args[:external_account_id])
    mappings = JSON.parse(File.read(args[:path]))

    result = Github::BridgeImport.new(account, mappings).run

    puts "Imported #{result.imported} mapping(s); skipped #{result.skipped} (no matching card)."
  end
end
