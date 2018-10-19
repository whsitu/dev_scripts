require 'tempfile'

db_name = ENV['DATABASE_NAME']
# name of tables to ignore in comma separated string: 'a,b,c,d,e'
tables_to_ignore = ENV['IGNORED_TABLE_NAMES'].split(',')
dump_file_name = ARGV[0]

list_file = Tempfile.new('list_file')

begin
  # Generate command list file
  system("pg_restore -l #{dump_file_name} > #{list_file.path}")

  list_file_content = list_file.read
  list_file.close

  # Comment out lines for restoring data
  tables_to_ignore.each do |table_name|
    command_regex = /[0-9]*;.*TABLE DATA public #{table_name} .*/
    command = command_regex.match(list_file_content)

    list_file_content = list_file_content.gsub(command_regex, "; #{command}")
  end

  # Overwrite file with commented out commands
  File.new(list_file.path, 'w').write(list_file_content)

  # Restore db without the ignored tables
  system("time pg_restore -v -j 4 --no-owner -d #{db_name} -L '#{list_file.path}' #{dump_file_name}")
ensure
  list_file.unlink
end
