import { Controller } from "@hotwired/stimulus"
import * as Credential from "webauthn-rails/credential";

export default class extends Controller {
  static targets = ["errorElement"]

  create(event) {
    event.preventDefault();
    var errorElement = this.errorElementTarget;
    event.detail.fetchResponse.response.json().then((response) => {
      console.log(response);
      if (event.detail.fetchResponse.succeeded) {
        var credentialOptions = response;
        Credential.get(credentialOptions);
      } else {
        errorElement.innerHTML = response["errors"][0];
        errorElement.hidden = false;
      }
    });
  }
}
