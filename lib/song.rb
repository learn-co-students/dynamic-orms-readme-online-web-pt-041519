require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song

  # Dynamically create table name from class name
  def self.table_name
    self.to_s.downcase.pluralize
  end

  # Return array of column names
  # Example: ["id", "name", "album"]
  def self.column_names

    # Create table info aray of hashes. Example:
    # {"cid"=>0,
    #   "name"=>"id",
    #   "type"=>"INTEGER",
    #   "notnull"=>0,
    #   "dflt_value"=>nil,
    #   "pk"=>1,
    #   0=>0,
    #   1=>"id",
    #   2=>"INTEGER",
    #   3=>0,
    #   4=>nil,
    #   5=>1},
    DB[:conn].results_as_hash = true
    sql = "pragma table_info('#{table_name}')"
    table_info = DB[:conn].execute(sql)

    # Collect column names and remove nils
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
  end

  # Create attr_accessors from column names
  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

  # Dynamic initialization from hash input
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  # Save object data to database, grab id
  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  # Access table name class method 
  def table_name_for_insert
    self.class.table_name
  end

  # Get column names from class method, remove nil id, and join array into string
  # Example return: "name, album"
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  # Iterate through column names, create SQL INSERT values, and join into string
  # Example return: "'the name of the song', 'the album of the song'"
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  # Find record by name
  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



