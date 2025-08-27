import "tw-elements"
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

const application = Application.start()
application.debug = true

// コントローラーを自動読み込み
eagerLoadControllersFrom("controllers", application)

export { application }
