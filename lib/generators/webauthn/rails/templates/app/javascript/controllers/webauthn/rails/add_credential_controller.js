import { Controller } from "@hotwired/stimulus"
import * as Credential from "webauthn-rails/credential";

export default class extends Controller {
  static targets = ["errorElement"]

  create(event) {
    event.preventDefault();
    var errorElement = this.errorElementTarget;
    event.detail.fetchResponse.response.json().then(response => {
      console.log(response);
      if (event.detail.fetchResponse.succeeded) {
        var credentialOptions = response;

        var credential_nickname = event.target.querySelector("input[name='credential[nickname]']").value;
        var callback_url = `/webauthn-rails/credentials/callback?credential_nickname=${credential_nickname}`

        Credential.create(encodeURI(callback_url), credentialOptions);
      } else {
        errorElement.innerHTML = response["errors"][0];
        errorElement.hidden = false;
      }
    });
  }
}

