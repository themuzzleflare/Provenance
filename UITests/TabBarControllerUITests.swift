import XCTest

final class TabBarControllerUITests: XCTestCase {
  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    XCUIApplication().launch()
  }

  func testAccountsTabBarItem() {
    testTabBarItem(tabBarItem: .accounts)
  }

  func testTagsTabBarItem() {
    testTabBarItem(tabBarItem: .tags)
  }

  func testCategoriesTabBarItem() {
    testTabBarItem(tabBarItem: .categories)
  }

  func testAboutTabBarItem() {
    testTabBarItem(tabBarItem: .about)
  }

  func testTabBarItem(tabBarItem: XCTabBarItem) {
    let elem = XCUIApplication().tabBars["Tab Bar"].buttons[tabBarItem.title]
    XCTAssertTrue(elem.exists)
    elem.tap()
    XCTAssertTrue(XCUIApplication().otherElements[tabBarItem.accessibilityIdentifier].exists)
  }
}
