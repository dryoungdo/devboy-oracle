const AUTH_KEY = 'devboy_auth';
const EXPECTED = 'YXJyYW9yYWNsZTpvcmFjbGVAMjAyNg==';

function checkAuth() {
  if (sessionStorage.getItem(AUTH_KEY) !== EXPECTED) {
    window.location.href = (window.location.pathname.includes('/articles/') ? '../' : '') + 'index.html';
  }
}

function tryLogin(user, pass) {
  var token = btoa(user + ':' + pass);
  if (token === EXPECTED) {
    sessionStorage.setItem(AUTH_KEY, token);
    return true;
  }
  return false;
}
