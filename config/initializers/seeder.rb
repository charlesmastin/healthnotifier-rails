require 'seed-fu/seeder'
module SeedFu
  class Seeder
    private
      def update_id_sequence # @@@ MONKEYPATCH!
        if @model_class.connection.adapter_name == "PostgreSQL"
        ## !!! DO NOTHING INSTEAD OF seed-fu's FUNKY BEHAVIOR:
          ##quoted_id       = @model_class.connection.quote_column_name(@model_class.primary_key)
          ##quoted_sequence = "'" + @model_class.sequence_name + "'"
          ##@model_class.connection.execute(
          ##  "SELECT pg_catalog.setval(" +
          ##    "#{quoted_sequence}," +
          ##    "(SELECT MAX(#{quoted_id}) FROM #{@model_class.quoted_table_name}) + 1" +
          ##  ");"
          ##)
        end
      end
  end
end
