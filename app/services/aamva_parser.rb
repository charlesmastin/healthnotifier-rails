class AAMVAParser
    def self.call(data)
        # qnd for the stuffs we care about
        attribute_map = {
            :DCS => 'last_name',
            :DAC => 'first_name',
            :DAD => 'middle_name',
            :DCT => 'allthenamesNY', # not in spec
            :DAA => 'allthenamesIL', # not in spec
            :DBB => 'birthdate', # CA mdY, IL Ymd, what the
            :DBC => 'gender', #1 male, 2 female, 9 n/a
            :DAY => 'eye_color', # BRN ANSI D-20 codes
            :DAU => 'height', # 071 IN (or) 181 CM 
            :DAG => 'address_line1',
            :DAI => 'city',
            :DAJ => 'state_province',
            :DAK => 'postal_code',
            :DCG => 'country',
            # truncated names checks
            :DAH => 'address_line2',
            :DAZ => 'hair_color',
            :DCU => 'suffix',
            :DCL => 'ethnicity', # meh
            :DAW => 'weight', # in pounds
            # :DAX => 'weight', # pounds
            :DDK => 'organ_donor',
        }

        # so basic stuffs, what to we care about really though
        # so, here's the quickest dirtiest thing we've ever done
        # read all lines, that aren't empty
        # TODO: add all the additional null check

        # TODO: jerry notes there can be corruption on first line,
        # find the second instance of "DL" to start

        attrs = {}
        data.split("\n").each do |line|
            if line.length >= 3
                if line.include?("ANSI") # \u001C\r ugggggugugugug start_with? bro
                    # CHOP off the start to the second instance of DL
                    # then you get yourself the first smushed key bro brizzle
                    if line.include?("DL") && line.length >= 5
                        ind = line.rindex("DL")
                        key = line[(ind+2)..(ind+4)]
                        value = line[(ind+5)..line.length]
                        attrs[key] = value.rstrip
                    end
                else
                    key = line[0,3]
                    # be sure to handle empty strings bra
                    value = line[3, line.length]
                    attrs[key] = value.rstrip
                end
            end
        end
        # the stuff we really care about bro
        json = {}
        if attrs.key?("DAC")
            json[:first_name] = attrs["DAC"].titleize
        end
        if attrs.key?("DCS")
            json[:last_name] = attrs["DCS"].titleize
        end
        if attrs.key?("DAD")
            json[:middle_name] = attrs["DAD"].titleize
        end
        # OFF SPEC, IL or old stuff, because CSV FOR LIFE
        if attrs.key?("DAA")
            delimiter = " "
            if attrs["DAA"].include?(",")
                delimiter = ","
            end
            names = attrs["DAA"].split(delimiter)
            if names[1] != nil
                json[:first_name] = names[1].titleize
            end
            if names[0] != nil
                json[:last_name] = names[0].titleize
            end
            if names[2] != nil
                json[:middle_name] = names[2].titleize
            end
        end
        # OFF SPEC NY, GA
        if attrs.key?("DCT")
            # NY uses " ", GA uses ","
            delimiter = " "
            if attrs["DCT"].include?(",")
                delimiter = ","
            end
            names = attrs["DCT"].split(delimiter)
            if names[0] != nil
                json[:first_name] = names[0].titleize
            end
            if names[1] != nil
                json[:middle_name] = names[1].titleize
            end
        end
        if attrs.key?("ZNG")
            delimiter = " "
            if attrs["ZNG"].include?(",")
                delimiter = ","
            end
            names = attrs["ZNG"].split(delimiter)
            if names[0] != nil
                json[:first_name] = names[0].titleize
            end
            if !attrs.key?("DCS")
                if names[2] != nil
                    json[:last_name] = names[2].titleize
                end
            end
            if names[1] != nil
                json[:middle_name] = names[1].titleize
            end
        end
        if attrs.key?("DBB")
            # format the way we usually send dates brod
            # do something smart bra, based on the document version code
            # and some documentation
            # can't trust that though, just try all the things then
            date = nil
            begin
                date = Date.strptime(attrs["DBB"], "%m%d%Y")
            rescue
                begin
                    date = Date.strptime(attrs["DBB"], "%Y%m%d")
                rescue
                    # well hell
                end
            end
            if date != nil
                json[:birthdate] = date
            end
        end

        # organ_donor
        if attrs.key?("DDK")
            # TODO: bro
        end

        # biometrics
        # height
        if attrs.key?("DAU")
            # inches, here, because we know we're gonna 
            h = attrs["DAU"]
            if h.downcase.include?("in")
                # zero padding bro I guess convert to a number
                # INCHES BRO
                begin
                    json[:height] = attrs["DAU"][0..3].to_i
                rescue
                    # nope
                end
            elsif h.downcase.include?("cm")
                # FOR LATER BRO, AKA, DEM CANADIAN PROVINCES, MEXICO, lol, naaaaaa
            else
                # just FIN, lol brolo, here goes nothing
                begin
                    inches = attrs["DAU"][0].to_i * 12
                    inches += attrs["DAU"][1..2].to_i
                    json[:height] = inches
                rescue
                    # oh hell
                end
            end
                
            # centimeters though
        end
        # weight
        if attrs.key?("DAW")
            json[:weight] = attrs["DAW"].to_i
        end

        # eye_color
        if attrs.key?("DAY")
            json[:eye_color] = map_eye_color(attrs["DAY"])
        end

        # hair_color
        if attrs.key?("DAZ")
            json[:hair_color] = map_hair_color(attrs["DAZ"])
        end

        # demographics

        # gender
        if attrs.key?("DBC")
            case attrs["DBC"]
            when "1"
                json[:gender] = "M"
            when "2"
                json[:gender] = "F"
            when "9"
                # yup, not sure what to do
            end
        end

        # address
        if attrs.key?("DAG")
            json[:address_line1] = attrs["DAG"].titleize
        end
        if attrs.key?("DAH")
            json[:address_line2] = attrs["DAH"].titleize
        end
        if attrs.key?("DAI")
            json[:city] = attrs["DAI"].titleize
        end
        if attrs.key?("DAJ")
            json[:state_province] = attrs["DAJ"]
        end

        if attrs.key?("DCG")
            # workaround hack bro, for some line parsing business on NY
            if attrs["DCG"].include?("USA")
                json[:country] = "US"
                if attrs.key?("DAK")
                    begin
                        json[:postal_code] = attrs["DAK"][0..4]
                    rescue
                        # nope
                    end
                end
            else
                # CANADA BRO BAS
                # do the 3 to 2 country conversion with a library or our service, later
                country = attrs["DCG"]
                if country == "CAN"
                    json[:country] = "CA"
                end
                if attrs.key?("DAK")
                    json[:postal_code] = attrs["DAK"]
                end
            end  
        end



        json
    end

    def self.map_eye_color(value)
        case value
        when "BLK"
            return "Black"
        when "BLU"
            return "Blue"
        when "BRO"
            return "Brown"
        when "BRN"
            return "Brown"
        # DIC Dichromatic # this where we used to have a left/right selector, w/e rare
        when "GRY"
            return "Gray"
        when "GRN"
            return "Green"
        when "HAZ"
            return "Hazel"
        when "MAR"
            return "Maroon"
        when "PNK"
            return "Pink"
        # UNK Unknown (Other)
        else
            return "Other"
        end
    end

    def self.map_hair_color(value)
        case value
        when "BAL"
            return "None" # aka Bald
        when "BLK"
            return "Black"
        when "BLU"
            return "Blue"
        when "BRO"
            return "Brown"
        when "BRN"
            return "Brown"
        when "GRY"
            return "Gray"
        when "RED"
            return "Red"
        when "SDY"
            return "Sandy"
        when "WHI"
            return "White"
        else
            return "Other"
        end
    end
end