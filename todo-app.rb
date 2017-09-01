require "selenium-webdriver"
require "rest-client"
require "test-unit"

class TodoAppTest < Test::Unit::TestCase
	def test_todo_app_test
		begin
			username = "you%40yourcompany.com"
			authkey = "12345"
			
			caps = Selenium::WebDriver::Remote::Capabilities.new

			caps["name"] = "Todo App Example"
			caps["build"] = "1.0"
			caps["browserName"] = "Chrome"      # pulls latest version by default
            		caps["platform"] = "Windows 8"      # to specify version, add caps["version"] = "desired version"
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
		    driver.manage.window.maximize
		    puts "Loading URL"
		    driver.navigate.to("http://crossbrowsertesting.github.io/todo-app.html")

		    puts "Clicking Checkbox"
		    driver.find_element(:name, "todo-4").click
		    puts "Clicking Checkbox"
		    driver.find_element(:name, "todo-5").click

		    elems = driver.find_elements(:class, "done-true")
		    assert_equal(2, elems.length)

		    puts "Entering Text"
		    driver.find_element(:id, "todotext").send_keys("Run your first Selenium Test")
		    driver.find_element(:id, "addbutton").click

		    spanText = driver.find_element(:xpath, "/html/body/div/div/div/ul/li[6]/span").text
		    assert_equal("Run your first Selenium Test", spanText, "Problem adding to-do")

		    "Archiving old to-dos"
		    driver.find_element(:link_text, "archive").click
		    elems = driver.find_elements(:class, "done-false")
		    assert_equal(4, elems.length, "Problem archiving to-dos")

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
