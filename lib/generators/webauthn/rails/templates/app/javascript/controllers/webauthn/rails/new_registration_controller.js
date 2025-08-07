import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["errorElement" , "credentialHiddenInput"];

  async create() {
    const optionsResponse = await fetch("/webauthn-rails/registration/create_options", {
      method: "POST",
      body: new FormData(this.element),
    });

    optionsResponse.json().then((data) => {
      if (optionsResponse.ok && data.user) {
        const credentialOptions = PublicKeyCredential.parseCreationOptionsFromJSON(data);

        navigator.credentials.create({ publicKey: credentialOptions }).then((credential) => {
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
