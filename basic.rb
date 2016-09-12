# Getting started: http://docs.seleniumhq.org/docs/03_webdriver.jsp
# API details: https://github.com/SeleniumHQ/selenium#selenium

# The gem "Rest-CLient" is highly recommended for making API calls
# install it with "gem install rest-client"

require "selenium-webdriver"
require "rest-client"

# username and authkey go here:
username = 'user@email.com'
authkey = '12345'

BaseUrl =   "https://#{username}:#{authkey}@crossbrowsertesting.com/api/v3"

# we use these functions to access the api
def getSnapshot(sessionId)
    # this returns the the snapshot's "hash" which is used in the 
    # setDescription function
    response = RestClient.post(BaseUrl + "/selenium/#{sessionId}/snapshots", 
        "selenium_test_id=#{sessionId}")
    snapshotHash = /(?<="hash": ")((\w|\d)*)/.match(response)[0]
    return snapshotHash
end

def setDescription(sessionId, snapshotHash, description)
    response = RestClient.put(BaseUrl + "/selenium/#{sessionId}/snapshots/#{snapshotHash}", 
        "description=#{description}")
end

def setScore(sessionId, score)
    # valid scores are 'pass', 'fail', and 'unset'
    response = RestClient.put(BaseUrl + "/selenium/#{sessionId}", 
        "action=set_score&score=#{score}")
end

caps = Selenium::WebDriver::Remote::Capabilities.new

caps["name"] = "Basic - Selenium Test Example"
caps["build"] = "1.0"
caps["browser_api_name"] = "IE10"
caps["os_api_name"] = "Win7x64-C2"
caps["screen_resolution"] = "1024x768"
caps["record_video"] = "true"
caps["record_network"] = "true"

driver = Selenium::WebDriver.for(:remote, 
    :url => "http://#{username}:#{authkey}@hub.crossbrowsertesting.com:80/wd/hub",
    :desired_capabilities => caps)

session_id = driver.session_id

puts session_id

score = "pass"

# maximize the window - DESKTOPS ONLY
driver.manage.window.maximize

driver.navigate.to("http://crossbrowsertesting.github.io/selenium_example_page.html")

expected_title = "Selenium Test Example Page"
actual_title = driver.title

if not (actual_title == expected_title)
    # if the actual title isn't what we expect, set the score to fail
    puts ("actual_t")
    score = "fail"
    message = "Error: #{driver.title} does not equal #{expected_title}" 
end

setScore(session_id, score)
if score == "fail"
    # if the test failed, take a snapshot and log the error
    snapshotHash = getSnapshot(session_id)
    setDescription(session_id, snapshotHash, $!.message)
end
driver.quit