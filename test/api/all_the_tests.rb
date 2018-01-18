require 'airborne'
require 'byebug'
require 'base64'


# this is a bad crutch for using local stuff vs the APIs BIZZLE
require File.expand_path("../../../config/environment", __FILE__)
require 'rspec/rails'

DEFAULT_API_AUTH_TOKEN = ''
DEFAULT_API_EMAIL = ''
DEFAULT_PATIENT_UUID = ''

DD_UUID = nil
DF_UUID = nil

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
# require './app/models/Account.rb'

Airborne.configure do |config|
  config.base_url = 'http://localhost:3000/api/v1'
  # TODO: we need a set of headers for both providers and non-providers, etc, etc, etc this suite is SUPER BASIC
  # TODO: re-run certain parts of the suite with malformed AUTH, but for kicks, test a few one-offs, we need to be certain which are wrapped vs have explicit lookups
  # rspec settings
  config.color = true
  config.tty = true
end

# config/environments/test.rb
#Rails.application.configure do
#  config.active_support.test_order = :sorted # or `:random` if you prefer
#end

describe 'sessions spec' do
    it 'should login successfully with valid credentials' do
        post '/auth/login' , { :Email => 'c+3@domain.com', :Password => 'changeme2016' }
        expect_json_types(AuthToken: :string)
    end

    it 'should fail login with incorrect password' do
        post '/auth/login' , { :Email => 'c+3@domain.com', :Password => 'changeme2017' }
        expect_status(400)
    end

    it 'should fail login with incorrect email' do
        post '/auth/login' , { :Email => 'c+3@domain.org', :Password => 'changeme2016' }
        expect_status(401)
    end
    # logout


    # use db connection to re-establish the token though, yea son
end

describe 'accounts spec' do
    it 'should send password reset with valid email' do
        post '/auth/reminder', { :Email => 'c+3@domain.com' }
        expect_status(200)
    end

    it 'should fail password reset with incorrect email' do
        post '/auth/reminder', { :Email => 'c+3@domain.org' }
        expect_status(404)
    end

    # register, passes, but we need to wipe the db so this can pass or generate a random email
    it 'should register successfully with a new email' do

        # cleanup and remove this user, from test run to test run
        """
        begin
            a = Account.where(:email => 'c+rspec@domain.com')
            a.patient.destroy_all()
            a.destroy_all()
        rescue
            # blabla
        end
        """

        begin
            file = File.open('./test/api/avatar1.jpg', 'rb')
            content = file.read
            file.close
            data = Base64.encode64(content)
        rescue
            data = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAgAAZABkAAD/7AARRHVja3kAAQAEAAAAPAAA/+4ADkFkb2JlAGTAAAAAAf/bAIQABgQEBAUEBgUFBgkGBQYJCwgGBggLDAoKCwoKDBAMDAwMDAwQDA4PEA8ODBMTFBQTExwbGxscHx8fHx8fHx8fHwEHBwcNDA0YEBAYGhURFRofHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8f/8AAEQgACgAKAwERAAIRAQMRAf/EAHgAAQEAAAAAAAAAAAAAAAAAAAQGAQACAwEAAAAAAAAAAAAAAAADBAABBQYQAAAEAwUJAQAAAAAAAAAAAAECAwQAMjPwETFSBVFhcYESkhMVNQYRAAECAggHAAAAAAAAAAAAAAABAxEC8CExUYGxwRPR4RJS0gQU/9oADAMBAAIRAxEAPwCLP+XaKsHD9sCS7Nit411kTJgCZSJGMACkFwKFUOYC9Vw7sIzHHYKvStR3TnrS7raIkIgvU6PkaTZyU83GBbs14z8jfbkN0j4a0syNGSoFW22JyKm8rNCL7MLcoIK8KYn/2Q=="
        end

        post '/account', {
            :FirstName => 'Chank',
            :LastName => 'Master',
            :Email => 'c+rspec101@domain.com',
            :Password => 'DonkeyTownUSA2016',
            :DOB => '01/01/1982',
            :MobilePhone => '4158964200',
            :ProfilePhoto => {
                :Name => 'tempdonkey.jpg',
                :Mimetype => 'image/jpg',
                :File => data
            }
        }
        expect_status(200)
    end

    xit 'should build out a whole bunch of fake profiles' do
        last_names = [
            'Cashmere',
            'Phoenix',
            'MacApple',
            'Flopple',
            'Levenworth',
            'Poowhistle',
            'Johnson',
            'Hammerhead',
            'LeMans',
            'Jupiter',
            'Bed',
            'Revilo',
            'Parachute',
            'Diablo',
            'Hickory',
            'Montenegro',
            'Vulture',
            'Blacksmith',
            'Violence',
            'Socks',
            'Heels',
            'Teddy',
            'Parquet',
            'Jones',
            'Hacksaw',
            'Spork',
            'Corduroy',
            'Everglades',
            'Radisson',
            'Doublesteve',
            'Montreal',
            'Backflip',
            'Pepperoni',
            'Fracas',
            'Lasagna',
            'VanLandingham',
            'Discotheque',
            'Nuggets',
            'Lupus',
            'Arugula',
            'Instagram',
            'McHector',
            'Colorado',
            'Champagne',
            'Lockjaw',
            'Hollandaise',
            'Buddha',
            'Waterslide',
            'Mascara',
            'Wobbles',
            'Toboggan',
            'Kerfuffle',
            'Smith',
            'Purple',
            'Switchblade',
            'Salkow',
            'Labrador',
            'Mocha',
            'Rose',
            'Brenda',
            'Pumpkin',
            'Skinner',
            'Remington',
            'Mistletoe',
            'Skorts',
            'Eleanor',
            'Beretta',
            'Sherman',
            'Popper',
            'Racecar',
            'Negroni',
            'Raylene',
            'Cardinal',
            'Telluride',
            'Decolletage',
            'Crossbow',
            'Porter',
            'Stout',
            'Lager',
            'Copacabana',
            'Skateboard',
            'Unicycle',
            'Hoverboard',
            'Dazzle',
            'Pizzazz',
            'O’Barkeep',
            'Nitrogen',
            'Starfeet',
            'McMartinhamson',
            'Houndstooth',
            'Camembert',
            'Hurley',
            'Trampoline',
        ]
        male_names = [
            'Lucius',
            'Jesse',
            'Dell',
            'Roger',
            'Demetrius',
            'Alonzo',
            'Dunk',
            'Salamander',
            'Serge',
            'Flip',
            'Ed',
            'Oliver',
            'Bushwood',
            'Lucenzo',
            'Victor',
            'Ferrari',
            'Nico',
            'Cobbler',
            'Jack',
            'Bobby',
            'Chunky',
            'Silk',
            'Gil',
            'Stegosaurus',
            'Rodney',
            'Sir Alistair',
            'Paul',
            'Giuseppe',
            'Pog',
            'Steve',
            'Beauregard',
            'Tex',
            'Nikolai',
            'Yolo',
            'Hank',
            'Magellan',
            'Bonezone',
            'Carl',
            'Teddy',
            'Kid',
            'Kale',
            'Luke',
            'Ludwig Von',
            'Hector',
            'Max',
            'Champ',
            'Samuel',
            'Jacques',
            'Christian',
            'Carlos'
        ]
        female_names = [
            'Natasha',
            'Xena',
            'Hilda',
            'Lisa',
            'Dana',
            'Heather',
            'Alicia',
            'Daisy',
            'Tatiana',
            'Monica',
            'Rose',
            'Mocha',
            'Alexandra',
            'Jacqueline',
            'Kat',
            'Penelope',
            'Holly',
            'Wendy',
            'Cassidy',
            'Rebecca',
            'Georgia',
            'Molly',
            'Martha',
            'Dina',
            'Contessa',
            'Robin',
            'April',
            'Trisha',
            'Allison',
            'Helen',
            'Emma',
            'Joan',
            'Kaylee',
            'Lola',
            'Sally',
            'Dolly',
            'Peggy',
            'Louise',
            'Carmella',
            'Erin',
            'Becky',
            'Allie',
            'Lindsay',
            'Mirandella',
            'Zooey',
            'Shirley',
            'Esther'
        ]
        r = Random.new
        total = 10
        email_base = r.rand(0..1000)
        while total > 0 do
            total -= 1
            li = r.rand(0...last_names.length)
            lastname = last_names[li]
            flops = r.rand(0..100)
            if flops % 2 == 0
                fi = r.rand(0...male_names.length)
                firstname = male_names[fi]
            else
                fi = r.rand(0...female_names.length)
                firstname = female_names[fi]
            end
            
            # starting offset for email zone
            email = "sample+#{email_base}#{total}@domain.com"

            # random DOB
            dob = Date.new(r.rand(1950..2016), r.rand(1..12), r.rand(1..29))
            # non-cycling
            begin
                file = File.open("./test/api/photos/128-#{r.rand(1..32)}.jpg", 'rb')
                content = file.read
                file.close
                data = Base64.encode64(content)
            rescue
                data = nil
            end

            post '/account', {
                :FirstName => firstname,
                :LastName => lastname,
                :Email => email,
                :Password => 'changeme2016',
                :DOB => dob.strftime("%m/%d/%Y"),
                :MobilePhone => '4152796521',
                :ProfilePhoto => {
                    :Name => 'tempdonkey.jpg',
                    :Mimetype => 'image/jpg',
                    :File => data
                }
            }

            # cool story bro, we need to associate these people now

        end

        # disable emailing

        # random generator

        # go from 0-100

        # while

        # random scenario

        # single

        # husband / wife

        # map back to the provider network with provider status

        

        

    end

    it 'should fail to register a duplicate account' do
        post '/account', {
            :FirstName => 'Chank',
            :LastName => 'Master',
            :Email => 'c+3@domain.com',
            :Password => 'DonkeyTownUSA2016',
            :DOB => '01/01/1982',
            :MobilePhone => '4158964200'
        }
        expect_status(400)
    end

    it 'should fail to register on incomplete request' do
        post '/account', {
            :FirstName => 'Chank',
            :LastName => 'Master',
            :Email => '',
            :Password => '',
            :DOB => '01/01/1982',
            :MobilePhone => '4158964200'
            # skipping that profile pic son
        }
        expect_status(500)
    end
end    

describe 'providers spec' do
    # valid woo hoo, needs different auth headers for a non-credentialed account
    xit 'should register successfully with a new email' do
        post '/provider-credentials', {
            :LicenseNumber => '19861989420',
            :LicenseBoard => 'DIY Physicians',
            :State => 'CA',
            :Expiration => '01/01/2020',
            :SupervisorName => 'Big Boss',
            :SupervisorEmail => 'c+rspec@domain.com',
            :SupervisorPhone => '4154205000',
            :SupervisorExt => ''
            # skipping that files son
        }, { 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
    end

    # existing credentialed provider
    # passes via 500 second line of defense past basic auth check

    # duplicate in-progress request
    # passed via hacking simulation

    # malformed
    # passes via 500, once it even passes all the other stuff 
    # patients??

    # scan

    # webview

    # webview expired coverage

    it 'should search email successfully' do
        get '/lifesquares/search', { 'params' => {'keywords' => 'c+3@domain.com'}, 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
        expect_json(Lifesquares: -> (lsqs){ expect(lsqs.length).to eq(1) })
    end

    it 'should search names successfully' do
        get '/lifesquares/search', { 'params' => {'keywords' => 'Chank Master'}, 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
        expect_json(Lifesquares: -> (lsqs){ expect(lsqs.length >= 1).to eq(true) })
    end

    it 'should search address successfully' do
        # TODO: put in real addresses based on setup fixture, not included
        get '/lifesquares/search', { 'params' => {'keywords' => 'Input An Address Here'}, 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
        expect_json(Lifesquares: -> (lsqs){ expect(lsqs.length >= 1).to eq(true) })
    end

    it 'should search geo successfully' do
        # TODO: put some real lat/lon in
        get '/lifesquares/nearby', { 'params' => {'latitude' => 'INPUT SOMETHING', 'longitude' => 'INPUT SOMETHING'}, 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
        expect_json(Lifesquares: -> (lsqs){ expect(lsqs.length >= 1).to eq(true) })
    end

    # document view
end

describe 'lifesquares spec' do
    # scan
    it 'should scan successfully' do
        get '/lifesquares/ABC123ABC', { 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
        expect_json_types(LifesquareId: :string)
    end

    it 'should fail scanning with malformed code' do
        get '/lifesquares/ABC123ABC789', { 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(404)
    end

    it 'should return a webview' do
        get '/lifesquares/abc123abc/webview', { 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
        # oddity accessing the header, but we can live with it
        # expect_header_contains("content-type", 'text/html')
        # expect(body).to include '<div class="tab" id="medical">'
        # expect(body).to include '<div class="tab" id="personal">'
        # expect(body).to include '<div class="tab" id="contacts">'
        # this is sure to break as we change the webview, but anyhow, this webview will be RIP 86' shortly
        # expect(body).to include "ABC 123 ABC"
        # check owner is true
    end

    # image

    # validate

    # assign

    # replace
end

describe 'patients spec' do
    # patients
    it 'should return my profiles' do
        get '/profiles' , { 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
        expect_json(Patients: -> (objects){ expect(objects.length >= 1).to eq(true) })
    end

    # profile photo API SON
    it 'should add photo and return success' do

        begin
            file = File.open('./test/api/avatar1.jpg', 'rb')
            content = file.read
            file.close
            data = Base64.encode64(content)
        rescue
            data = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAgAAZABkAAD/7AARRHVja3kAAQAEAAAAPAAA/+4ADkFkb2JlAGTAAAAAAf/bAIQABgQEBAUEBgUFBgkGBQYJCwgGBggLDAoKCwoKDBAMDAwMDAwQDA4PEA8ODBMTFBQTExwbGxscHx8fHx8fHx8fHwEHBwcNDA0YEBAYGhURFRofHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8f/8AAEQgACgAKAwERAAIRAQMRAf/EAHgAAQEAAAAAAAAAAAAAAAAAAAQGAQACAwEAAAAAAAAAAAAAAAADBAABBQYQAAAEAwUJAQAAAAAAAAAAAAECAwQAMjPwETFSBVFhcYESkhMVNQYRAAECAggHAAAAAAAAAAAAAAABAxEC8CExUYGxwRPR4RJS0gQU/9oADAMBAAIRAxEAPwCLP+XaKsHD9sCS7Nit411kTJgCZSJGMACkFwKFUOYC9Vw7sIzHHYKvStR3TnrS7raIkIgvU6PkaTZyU83GBbs14z8jfbkN0j4a0syNGSoFW22JyKm8rNCL7MLcoIK8KYn/2Q=="
        end

        post '/profiles/' + DEFAULT_PATIENT_UUID + '/profile-photo', {
            :ProfilePhoto => {
                :Name => 'tempdonkey.jpg',
                :Mimetype => 'image/jpg',
                :File => data
            },
            :Crop => {
                :Width => 320,
                :Height => 320,
                :OriginX => 100,
                :OriginY => 100
            }
            # skipping that files son
        }, { 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
    end

    it 'should return an image' do
        get '/profiles/' + DEFAULT_PATIENT_UUID + '/profile-photo', { 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
    end

    it 'should delete the photo and return success' do
        # TODO: temp workaround https://github.com/brooklynDev/airborne/issues/105
        delete '/profiles/' + DEFAULT_PATIENT_UUID + '/profile-photo', { :Donkey => 'Kong' }, { 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
    end
end

xdescribe 'patient network spec' do
    # search

    # search unsearchable

    # invite

    # join

    # network webview

    # accept

    # network webview

    # remove / delete

    # network webview
end

# temp name
xdescribe 'stripe spec' do

    # tokenize cards for use in this suite
    # 4242424242424242 visa
    # 5555555555554444 mc
    # 378282246310005 amex
    # 6011111111111117 discover

    # first charge for a new customer
    it 'should create a charge with new customer' do
        token_id = CreditCardService.tokenize_card({
            :number => 4242424242424242,
            :exp_month => 1,
            :exp_year => 2020,
            :cvc => 123
        })

        # create customer
        # customer = CreditCardService.get_or_create()

        # save
        


    end

    # auxillary item here, could be bundled in previous test
    it 'should update patient personal information' do
        # this is to test the resiliancy on how we store the customer identifier
    end

    it 'should create a charge with an existing customer' do

    end

    it 'should create a subscription with a new customer' do

    end

    it 'should cancel a subscription' do

    end

    it 'should create a subscription with an existing customer' do

    end

    it 'should cancel a subscription' do

    end

    # cleanup task, not part of typical flow
    it 'should remove a customer' do

    end
end

describe 'documents spec' do
    it 'should add document with 2 images and return info' do

        begin
            file = File.open('./test/api/avatar1.jpg', 'rb')
            content = file.read
            file.close
            data = Base64.encode64(content)
        rescue
            data = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAgAAZABkAAD/7AARRHVja3kAAQAEAAAAPAAA/+4ADkFkb2JlAGTAAAAAAf/bAIQABgQEBAUEBgUFBgkGBQYJCwgGBggLDAoKCwoKDBAMDAwMDAwQDA4PEA8ODBMTFBQTExwbGxscHx8fHx8fHx8fHwEHBwcNDA0YEBAYGhURFRofHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8f/8AAEQgACgAKAwERAAIRAQMRAf/EAHgAAQEAAAAAAAAAAAAAAAAAAAQGAQACAwEAAAAAAAAAAAAAAAADBAABBQYQAAAEAwUJAQAAAAAAAAAAAAECAwQAMjPwETFSBVFhcYESkhMVNQYRAAECAggHAAAAAAAAAAAAAAABAxEC8CExUYGxwRPR4RJS0gQU/9oADAMBAAIRAxEAPwCLP+XaKsHD9sCS7Nit411kTJgCZSJGMACkFwKFUOYC9Vw7sIzHHYKvStR3TnrS7raIkIgvU6PkaTZyU83GBbs14z8jfbkN0j4a0syNGSoFW22JyKm8rNCL7MLcoIK8KYn/2Q=="
        end

        post '/document', {
            :PatientId => DEFAULT_PATIENT_UUID,
            :Files => [{
                :Name => 'tempdonkey.jpg',
                :Mimetype => 'image/jpg',
                :File => data
            },
            {
                :Name => 'tempdonkey.jpg',
                :Mimetype => 'image/jpg',
                :File => data
            }
            ],
            :DirectiveType => 'MEDICAL_NOTE',
            :Privacy => 'private'
            
            # skipping that files son
        }, { 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
        expect_json_types(DocumentUuid: :string)
        expect_json_types(FirstChildUuid: :string)
        expect_json(Size: -> (size){ expect(size == 2).to eq(true) })
    end

    # add directive with pdf (with 2 pages)
    it 'should add pdf document with 2 pages and return info' do

        begin
            file = File.open('./test/api/polst.pdf', 'rb')
            content = file.read
            file.close
            data = Base64.encode64(content)
        rescue
            data = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAgAAZABkAAD/7AARRHVja3kAAQAEAAAAPAAA/+4ADkFkb2JlAGTAAAAAAf/bAIQABgQEBAUEBgUFBgkGBQYJCwgGBggLDAoKCwoKDBAMDAwMDAwQDA4PEA8ODBMTFBQTExwbGxscHx8fHx8fHx8fHwEHBwcNDA0YEBAYGhURFRofHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8f/8AAEQgACgAKAwERAAIRAQMRAf/EAHgAAQEAAAAAAAAAAAAAAAAAAAQGAQACAwEAAAAAAAAAAAAAAAADBAABBQYQAAAEAwUJAQAAAAAAAAAAAAECAwQAMjPwETFSBVFhcYESkhMVNQYRAAECAggHAAAAAAAAAAAAAAABAxEC8CExUYGxwRPR4RJS0gQU/9oADAMBAAIRAxEAPwCLP+XaKsHD9sCS7Nit411kTJgCZSJGMACkFwKFUOYC9Vw7sIzHHYKvStR3TnrS7raIkIgvU6PkaTZyU83GBbs14z8jfbkN0j4a0syNGSoFW22JyKm8rNCL7MLcoIK8KYn/2Q=="
        end

        post '/document', {
            :PatientId => DEFAULT_PATIENT_UUID,
            :Files => [{
                :Name => 'tempdonkey.pdf',
                :Mimetype => 'application/pdf',
                :File => data
            }
            ],
            :DirectiveType => 'POLST',
            :Privacy => 'provider'
            
            # skipping that files son
        }, { 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
        expect_json_types(DocumentUuid: :string)
        expect_json_types(FirstChildUuid: :string)
        expect_json(Size: -> (size){ expect(size == 2).to eq(true) })

        DD_UUID = json_body[:DocumentUuid]
        DF_UUID = json_body[:FirstChildUuid]
    end

    it 'should return document data' do
        if DD_UUID == nil
            DD_UUID = 'NTQz'
        end
        get '/documents/' + DD_UUID, { 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
    end

    it 'should return an image' do
        if DF_UUID == nil
            DF_UUID = 'ZG9jdW1lbnQtZGlnaXRpemVkLWZpbGVzLzU0My8xX3RlbXBkb25rZXkuanBn'
        end
        get '/files/' + DF_UUID, { 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
    end

    it 'should delete the document and return success' do
        # TODO: temp workaround https://github.com/brooklynDev/airborne/issues/105
        delete '/document/' + DD_UUID, { :Donkey => 'Kong' }, { 'X-Account-Token' => DEFAULT_API_AUTH_TOKEN, 'X-Account-Email' => DEFAULT_API_EMAIL }
        expect_status(200)
    end
end