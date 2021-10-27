import XCTest

final class TabBarControllerUITests: XCTestCase {
  override func setUp() {
    super.setUp()
    let app = XCUIApplication()
    app.launch()
  }

  func testAccountsTabBarItem() {
    testTabBarItem(title: "Accounts")
  }

  func testTagsTabBarItem() {
    testTabBarItem(title: "Tags")
  }

  func testCategoriesTabBarItem() {
    testTabBarItem(title: "Categories")
  }

  func testAboutTabBarItem() {
    testTabBarItem(title: "About")
  }

  func testTabBarItem(title: String) {
    let elem = XCUIApplication().tabBars["Tab Bar"].buttons[title]
    XCTAssertTrue(elem.exists)
    elem.tap()
    sleep(2)
    XCTAssertTrue(XCUIApplication().navigationBars[title].exists || XCUIApplication().navigationBars["Error"].exists)
  }
}
