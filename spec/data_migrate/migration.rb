require 'spec_helper'

if Rails::VERSION::MAJOR >= 5
  subject = DataMigrate::MigrationFive
else
  subject = DataMigrate::Migration
end

describe subject do
  it "uses correct table name" do
    expect(subject.table_name).to eq("data_migrations")
  end

  it "uses correct index name" do
    expect(subject).to receive(:table_name_prefix) { "" }
    expect(subject).to receive(:table_name_suffix) { "" }
    expect(subject.primary_key).to eq("version")
  end
end
