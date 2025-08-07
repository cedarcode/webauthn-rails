import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["errorElement", "credentialHiddenInput"];

  async create() {
    const optionsResponse = await fetch("/webauthn-rails/session/get_options", {
      method: "POST",
      body: new FormData(this.element),
    });

    optionsResponse.json().then((data) => {
      if (optionsResponse.ok) {
        const credentialOptions = PublicKeyCredential.parseRequestOptionsFromJSON(data);

        navigator.credentials.get({ publicKey: credentialOptions }).then((credential) => {
          this.credentialHiddenInputTarget.value = JSON.stringify(credential);

          this.element.submit();
        });
      } else {
        this.#showError(data.errors?.[0] || "Unknown error");
      }
    });
  }

  #showError(message) {
    this.errorElementTarget.innerHTML = message;
    this.errorElementTarget.hidden = false;
  }
}
