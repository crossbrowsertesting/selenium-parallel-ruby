# Getting started: http://docs.seleniumhq.org/docs/03_webdriver.jsp
# API details: https://github.com/SeleniumHQ/selenium#selenium

# The gem "Rest-CLient" is highly recommended for making API calls
# install it with "gem install rest-client"

# For creating unit tests, we recommend test-unit
# Install it with "gem install test-unit"

require "selenium-webdriver"
require "rest-client"
require "test-unit"

class DragAndDropTest < Test::Unit::TestCase
	def test_drag_and_drop_test
		begin
			username = "you%40yourcompany.com"
			authkey = "12345"

			caps = Selenium::WebDriver::Remote::Capabilities.new

			caps["name"] = "Drag-and-Drop Example"
			caps["build"] = "1.0"
			caps["browser_api_name"] = "Chrome53"
			caps["os_api_name"] = "Win8"
			caps["screen_resolution"] = "1024x768"
			caps["record_video"] = "true"
			caps["record_network"] = "true"

			driver = Selenium::WebDriver.for(:remote,
			:url => "http://#{username}:#{authkey}@hub.crossbrowsertesting.com:80/wd/hub",
			:desired_capabilities => caps)

			session_id = driver.session_id

		    score = "pass"
		    cbt_api = CBT_API.new
		    # maximize the window - DESKTOPS ONLY
		    # driver.manage.window.maximize

		    puts "Loading URL"
		    driver.navigate.to("http://crossbrowsertesting.github.io/drag-and-drop.html")

		    # first, let's grab the draggable element
		    puts "Grabbing draggable element"
		    from = driver.find_element(:id, "draggable")

		    # then, we'll grab the droppable element
		    puts "Grabbing droppable element"
		    to = driver.find_element(:id, "droppable")

		    # We'll use actions to click and hold the element, drag it, the drop it appropriately
		    puts "Dragging and dropping element"
		    driver.action.click_and_hold(from).perform
		    driver.action.move_to(to).perform
		    driver.action.release.perform

		    # we'll assert the final state of the droppable element to ensure its in the state we want.
		    droppableText = driver.find_element(:xpath, "//*[@id=\"droppable\"]/p").text
		    assert_equal("Dropped!", droppableText)

		    puts "Taking Snapshot"
		    cbt_api.getSnapshot(session_id)
		    cbt_api.setScore(session_id, "pass")

		rescue Exception => ex
		    puts ("#{ex.class}: #{ex.message}")
		    cbt_api.setScore(session_id, "fail")
		ensure     
		    driver.quit
		end
	end
end

class CBT_API
	@@username = 'you%40yourcompany.com'
	@@authkey = '12345'
	@@BaseUrl =   "https://#{@@username}:#{@@authkey}@crossbrowsertesting.com/api/v3"
	def getSnapshot(sessionId)
	    # this returns the the snapshot's "hash" which is used in the
	    # setDescription function
	    response = RestClient.post(@@BaseUrl + "/selenium/#{sessionId}/snapshots",
	        "selenium_test_id=#{sessionId}")
	    snapshotHash = /(?<="hash": ")((\w|\d)*)/.match(response)[0]
	    return snapshotHash
	end

	def setDescription(sessionId, snapshotHash, description)
	    response = RestClient.put(@@BaseUrl + "/selenium/#{sessionId}/snapshots/#{snapshotHash}",
	        "description=#{description}")
	end

	def setScore(sessionId, score)
	    # valid scores are 'pass', 'fail', and 'unset'
	    response = RestClient.put(@@BaseUrl + "/selenium/#{sessionId}",
	        "action=set_score&score=#{score}")
	end
end