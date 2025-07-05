import reactLogo from "./assets/react.svg";
import viteLogo from "/vite.svg";
import "./App.css";

const APP_API_URL = "/api/test";

function App() {
  return (
    <>
      <div>
        <a href="https://vite.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>Vite + React</h1>
      <div className="card">
        <ApiTestButton />
        <p>
          Edit <code>src/App.tsx</code> and save to test HMR
        </p>
      </div>
      <p className="read-the-docs">
        Click on the Vite and React logos to learn more
      </p>
    </>
  );
}

function ApiTestButton() {
  function handleClick() {
    const options = {
      method: "POST",
    };
    fetch(APP_API_URL, options)
      .then((response: Response) => {
        if (!response.ok) {
          throw new Error(`HTTP error! Status: ${response.status}`);
        }
        return response.json();
      })
      .then((data) => {
        console.log("Fetched Data:", data);
      })
      .catch((err) => {
        console.error("Fetch error: ", err);
      });
  }

  return (
    <button type="button" className="RegistryAPI" onClick={handleClick}>
      test
    </button>
  );
}

export default App;
