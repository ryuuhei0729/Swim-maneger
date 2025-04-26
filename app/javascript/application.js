// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import "./controllers"
import { Modal, Ripple, initTE } from "tw-elements";

// Stimulusアプリケーションの設定
const application = Application.start()
application.debug = true

// コントローラーを自動読み込み
eagerLoadControllersFrom("controllers", application)

initTE({ Modal, Ripple });

export { application }



