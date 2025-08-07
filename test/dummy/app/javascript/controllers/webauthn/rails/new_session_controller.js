import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["errorElement", "credentialHiddenInput"];

  async create() {
    const optionsResponse = await fetch("/webauthn-rails/session/get_options", {
      method: "POST",
      body: new FormData(this.element),
    });

    const optionsJson = await optionsResponse.json();

    if (optionsResponse.ok) {
      const credentialOptions = PublicKeyCredential.parseRequestOptionsFromJSON(optionsJson);
      const credential = await navigator.credentials.get({ publicKey: credentialOptions });

      this.credentialHiddenInputTarget.value = JSON.stringify(credential);

      this.element.submit();
    } else {
      this.#showError(optionsJson.errors?.[0] || "Unknown error");
    }
  }

  #showError(message) {
    this.errorElementTarget.innerHTML = message;
    this.errorElementTarget.hidden = false;
  }
}
