// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"

// Stimulusアプリケーションの設定
const application = Application.start()
application.debug = false
window.Stimulus = application

export { application }

// コントローラーの読み込み
import "./index"
