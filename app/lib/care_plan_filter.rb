# TODO: find a better location for this logic
# and perhaps separate the filters more
module CarePlanFilter

  def self.match?(care_plan, patient)
    filter = build(care_plan.filters)
    filter.match?(patient)
  end

  def self.build(filter_definition)
    filter = nil
    case filter_definition
    when Hash
      filter_type = filter_definition["type"]
      filter_clazz = TYPES[filter_type]
      if filter_clazz
        filter = filter_clazz.new(filter_definition["parameters"])
      else
        logger.error "Ignoring unknown filter type: #{filter_type}"
        filter = CarePlanNilFilter.new
      end
    when Array
      filter = CarePlanOrFilter.new(filter_definition)
    else
      filter = CarePlanNilFilter.new
    end
    filter
  end

  def self.get_codes(type, parameters)
    case parameters
    when Hash
      array = [parameters]
    when Array
      array = parameters
    else
      array = Array.new
    end
    codes = array.select { |m| m[type] && m[type]["code"] }.collect { |m| m[type]["code"] }
    codes
  end

  # NIL FILTER
  # No JSON. Used as the default filter if the type isn't known or nil is provided
  class CarePlanNilFilter
    def match?(patient)
      true
    end
  end


  # OR FILTER
  # This is the default filter used if an Array is provided
  # over 65 or has diabetes
  # {"type": "or", "parameters": [
  #   {"type": "age", "parameters": {"minimum": {"value": "65", "unit": "year"}}},
  #   {"type": "condition", "parameters": {"imo": {"code": "41884"}}}
  # ]}
  # or simply
  # [
  #   {"type": "age", "parameters": {"minimum": {"value": "65", "unit": "year"}}},
  #   {"type": "condition", "parameters": {"imo": {"code": "41884"}}}
  # ]
  class CarePlanOrFilter
    def initialize(filter_parameters)
      case filter_parameters
      when Array
        @filters = build_filters(filter_parameters)
      else
        @filters = Array.new
      end
    end

    def build_filters(filter_parameters)
      filters = Array.new
      if filter_parameters
        filter_parameters.each do |filter_parameters|
          filter = CarePlanFilter.build(filter_parameters)
          filters << filter if filter
        end
      end
      filters
    end

    def match?(patient)
      @filters.empty? || @filters.any? { |f| f.match?(patient) }
    end
  end


  # AND FILTER
  # over 65 and takes morphine
  # {"type": "and", "parameters": [
  #   {"type": "age", "parameters": {"minimum": {"value": "65", "unit": "year"}}},
  #   {"type": "medication", "parameters": {"imo": {"code": "126701"}}}
  # ]}
  class CarePlanAndFilter
    def initialize(filter_parameters)
      case filter_parameters
      when Array
        @filters = build_filters(filter_parameters)
      else
        @filters = Array.new
      end
    end

    def build_filters(filter_parameters)
      filters = Array.new
      if filter_parameters
        filter_parameters.each do |filter_parameters|
          filter = CarePlanFilter.build(filter_parameters)
          filters << filter if filter
        end
      end
      filters
    end

    def match?(patient)
      @filters.all? { |f| f.match?(patient) }
    end
  end


  # NOT FILTER
  # does not have diabetes
  # {"type": "not", "parameters": {"type": "condition", "parameters": {"imo": {"code": "41884"}}}}
  class CarePlanNotFilter
    def initialize(filter_parameters)
      case filter_parameters
      when Hash
        @filter = build_filter(filter_parameters)
      else
        @filter = CarePlanNilFilter.new
      end
    end

    def build_filter(filter_parameters)
      filter = CarePlanNilFilter
      filter = CarePlanFilter.build(filter_parameters) if filter_parameters
      filter
    end

    def match?(patient)
      !@filter.match?(patient)
    end
  end


  # AGE FILTER
  # <= 6 months old
  # {"type": "age", "parameters": {"maximum": {"value": "6", "unit": "month"}}}
  # >= 65 years old
  # {"type": "age", "parameters": {"minimum": {"value": "65", "unit": "year"}}}
  # 18-65 years old
  # {"type": "age", "parameters": {"minimum": {"value": "18", "unit": "year"}, "maximum": {"value": "65", "unit": "year"}}}
  class CarePlanAgeFilter
    def initialize(filter_parameters)
      @latest_birthdate = calculate_birthdate_for_age(filter_parameters["minimum"], 0)
      @earliest_birthdate = calculate_birthdate_for_age(filter_parameters["maximum"], 200)
    end

    def calculate_birthdate_for_age(age_definition, default_years)
      today = Date.today
      if age_definition
        value = age_definition["value"].to_i
        unit = age_definition["unit"]
      else
        value = default_years
        unit = "year"
      end
      case unit
      when "year"
        birthdate = (today << (value * 12)) 
      when "month"
        birthdate = (today << value)
      when "week"
        birthdate = (today - (value*7))
      when "day"
        birthdate = (today - value)
      end
      birthdate
    end

    def match?(patient)
      (patient.birthdate >= @earliest_birthdate) && (patient.birthdate <= @latest_birthdate)
    end

  end

  # ALLERGY FILTER
  # imo
  # {"type": "allergy", "parameters": {"imo": {"code": "807238"}}}
  # imo/icd9/search term (only imo, icd9, and icd10 are currently used)
  # {"type": "allergy", "parameters": {"imo": {"code": "807238"}, "icd9": {"code": "V14.0"}, "term": "Penicillin allergy"}}
  # multiple imo codes
  # {"type" => "allergy", "parameters"=> [{"imo"=>{"code"=>"824536"}}, {"imo"=>{"code"=>"807238"}}]}
  class CarePlanAllergyFilter
    def initialize(filter_parameters)
      @imo_codes = CarePlanFilter.get_codes("imo", filter_parameters)
      @icd9_codes = CarePlanFilter.get_codes("icd9", filter_parameters)
      @icd10_codes = CarePlanFilter.get_codes("icd10", filter_parameters)
    end

    def match?(patient)
      patient.allergies.any? {
        |m| @imo_codes.include?(m.imo_code) || @icd9_codes.include?(m.icd9_code) || @icd10_codes.include?(m.icd10_code)
      }
    end
  end

  # CONDITION FILTER
  # imo
  # {"type": "condition", "parameters": {"imo": {"code": "88575"}}}
  # imo/icd9/search term (only imo, icd9, and icd10 are currently used)
  # {"type": "condition", "parameters": {"imo": {"code": "88575"}, "icd9": {"code": "268.9"}, "term": "Vitamin D deficiency"}}
  # multiple imo codes
  # {"type" => "condition", "parameters"=> [{"imo"=>{"code"=>"88575"}}, {"imo"=>{"code"=>"41884"}}]}
  class CarePlanConditionFilter
    def initialize(filter_parameters)
      @imo_codes = CarePlanFilter.get_codes("imo", filter_parameters)
      @icd9_codes = CarePlanFilter.get_codes("icd9", filter_parameters)
      @icd10_codes = CarePlanFilter.get_codes("icd10", filter_parameters)
    end

    def match?(patient)
      patient.conditions.any? {
        |m| @imo_codes.include?(m.imo_code) || @icd9_codes.include?(m.icd9_code) || @icd10_codes.include?(m.icd10_code)
      }
    end
  end

  # IMMUNIZATION FILTER
  # imo
  # {"type": "immunization", "parameters": {"imo": {"code": "88575"}}}
  # imo/icd9/search term (only imo, icd9, and icd10 are currently used)
  # {"type": "immunization", "parameters": {"imo": {"code": "88575"}, "icd9": {"code": "268.9"}, "term": "Vitamin D deficiency"}}
  # multiple imo codes
  # {"type" => "immunization", "parameters"=> [{"imo"=>{"code"=>"88575"}}, {"imo"=>{"code"=>"41884"}}]}
  # TODO: match only if the immunization is up to date
  class CarePlanImmunizationFilter
    def initialize(filter_parameters)
      @imo_codes = CarePlanFilter::get_codes("imo", filter_parameters)
      @icd9_codes = CarePlanFilter::get_codes("icd9", filter_parameters)
      @icd10_codes = CarePlanFilter::get_codes("icd10", filter_parameters)
    end

    def match?(patient)
      patient.immunizations.any? {
        |m| @imo_codes.include?(m.imo_code) || @icd9_codes.include?(m.icd9_code) || @icd10_codes.include?(m.icd10_code)
      }
    end
  end

  # PROCEDURE FILTER
  # imo
  # {"type": "procedure", "parameters": {"imo": {"code": "10066545"}}}
  # imo/icd9/search term (only imo, icd9, and icd10 are currently used)
  # {"type": "procedure", "parameters": {"imo": {"code": "10066545"}, "icd9": {"code": "525.50"}, "term": "Wisdom teeth removed"}}
  # multiple imo codes
  # {"type" => "procedure", "parameters"=> [{"imo"=>{"code"=>"10066545"}}, {"imo"=>{"code"=>"1715085"}}]}
  class CarePlanProcedureFilter
    def initialize(filter_parameters)
      @imo_codes = CarePlanFilter.get_codes("imo", filter_parameters)
      @icd9_codes = CarePlanFilter.get_codes("icd9", filter_parameters)
      @icd10_codes = CarePlanFilter.get_codes("icd10", filter_parameters)
    end

    def match?(patient)
      patient.procedures.any? {
        |m| @imo_codes.include?(m.imo_code) || @icd9_codes.include?(m.icd9_code) || @icd10_codes.include?(m.icd10_code)
      }
    end
  end

  # MEDICATION FILTER
  # imo
  # {"type": "medication", "parameters": {"imo": {"code": "126701"}}}
  # imo/icd9/search term (only imo, icd9, and icd10 are currently used)
  # {"type": "medication", "parameters": {"imo": {"code": "126701"}, "rxnorm": {"code": "7052"}, "term": "Morphine"}}
  # multiple rxnorm codes
  # {"type" => "medication", "parameters"=> [{"rxnorm"=>{"code"=>"7052"}}, {"rxnorm"=>{"code"=>"84815"}}]}
  class CarePlanMedicationFilter
    def initialize(filter_parameters)
      @imo_codes = CarePlanFilter.get_codes("imo", filter_parameters)
      # TODO: add rxnorm support
    end

    def match?(patient)
      patient.medications.any? { |m| @imo_codes.include?(m.imo_code) }
    end
  end

  TYPES = {
    "and" => CarePlanAndFilter,
    "not" => CarePlanNotFilter,
    "or" => CarePlanOrFilter,
    "age" => CarePlanAgeFilter,
    "allergy" => CarePlanAllergyFilter,
    "condition" => CarePlanConditionFilter,
    "immunization" => CarePlanImmunizationFilter,
    "procedure" => CarePlanProcedureFilter,
    "medication" => CarePlanMedicationFilter
  }

end