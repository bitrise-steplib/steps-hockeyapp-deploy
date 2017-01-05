package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"os"
	"os/exec"
	"strings"

	"time"

	"github.com/bitrise-io/go-utils/log"
	"github.com/bitrise-io/go-utils/pathutil"
	"github.com/bitrise-io/go-utils/retry"
)

const (
	hockeyAppUploadAppURL            = "https://rink.hockeyapp.net/api/2/apps/upload"
	hockeyAppUploadNewVersionURLForm = "https://rink.hockeyapp.net/api/2/apps/%s/app_versions/upload"

	hockeyAppDeployStatusKey     = "HOCKEYAPP_DEPLOY_STATUS"
	hockeyAppDeployStatusSuccess = "success"
	hockeyAppDeployStatusFailed  = "failed"

	hockeyAppDeployPublicURLKey = "HOCKEYAPP_DEPLOY_PUBLIC_URL"
	hockeyAppDeployBuildURLKey  = "HOCKEYAPP_DEPLOY_BUILD_URL"
	hockeyAppDeployConfigURLKey = "HOCKEYAPP_DEPLOY_CONFIG_URL"
)

// ConfigsModel ...
type ConfigsModel struct {
	IPAPath  string
	DSYMPath string

	APIToken string
	AppID    string

	Notes          string
	NotesType      string
	Notify         string
	Status         string
	Mandatory      string
	Tags           string
	CommitSHA      string
	BuildServerURL string
	RepositoryURL  string
}

func createConfigsModelFromEnvs() ConfigsModel {
	return ConfigsModel{
		IPAPath:  os.Getenv("ipa_path"),
		DSYMPath: os.Getenv("dsym_path"),

		APIToken: os.Getenv("api_token"),
		AppID:    os.Getenv("app_id"),

		Notes:          os.Getenv("notes"),
		NotesType:      os.Getenv("notes_type"),
		Notify:         os.Getenv("notify"),
		Status:         os.Getenv("status"),
		Mandatory:      os.Getenv("mandatory"),
		Tags:           os.Getenv("tags"),
		CommitSHA:      os.Getenv("commit_sha"),
		BuildServerURL: os.Getenv("build_server_url"),
		RepositoryURL:  os.Getenv("repository_url"),
	}
}

func (configs ConfigsModel) print() {
	log.Infof("Configs:")

	log.Printf("- IPAPath: %s", configs.IPAPath)
	log.Printf("- DSYMPath: %s", configs.DSYMPath)

	log.Printf("- APIToken: %s", configs.APIToken)
	log.Printf("- AppID: %s", configs.AppID)

	log.Printf("- Notes: %s", configs.Notes)
	log.Printf("- NotesType: %s", configs.NotesType)
	log.Printf("- Notify: %s", configs.Notify)
	log.Printf("- Status: %s", configs.Status)
	log.Printf("- Mandatory: %s", configs.Mandatory)
	log.Printf("- Tags: %s", configs.Tags)
	log.Printf("- CommitSHA: %s", configs.CommitSHA)
	log.Printf("- BuildServerURL: %s", configs.BuildServerURL)
	log.Printf("- RepositoryURL: %s", configs.RepositoryURL)
}

func (configs ConfigsModel) validate() error {
	if configs.IPAPath == "" {
		return errors.New("no IPAPath parameter specified")
	}
	if exist, err := pathutil.IsPathExists(configs.IPAPath); err != nil {
		return fmt.Errorf("failed to check if IPAPath exist at: %s, error: %s", configs.IPAPath, err)
	} else if !exist {
		return fmt.Errorf("IPAPath not exist at: %s", configs.IPAPath)
	}

	if configs.DSYMPath != "" {
		if exist, err := pathutil.IsPathExists(configs.DSYMPath); err != nil {
			return fmt.Errorf("failed to check if DSYMPath exist at: %s, error: %s", configs.DSYMPath, err)
		} else if !exist {
			return fmt.Errorf("DSYMPath not exist at: %s", configs.DSYMPath)
		}
	}

	if configs.APIToken == "" {
		return errors.New("no APIToken parameter specified")
	}

	return nil
}

// ResponseModel ...
type ResponseModel struct {
	ConfigURL string `json:"config_url"`
	PublicURL string `json:"public_url"`
	BuildURL  string `json:"build_url"`
}

func failWithMessage(format string, v ...interface{}) {
	log.Errorf(format, v...)
	os.Exit(1)
}

func exportEnvironmentWithEnvman(keyStr, valueStr string) error {
	envman := exec.Command("envman", "add", "--key", keyStr)
	envman.Stdin = strings.NewReader(valueStr)
	envman.Stdout = os.Stdout
	envman.Stderr = os.Stderr
	return envman.Run()
}

func createRequest(url string, fields, files map[string]string, apiToken string) (*http.Request, error) {
	var b bytes.Buffer
	w := multipart.NewWriter(&b)

	// Add fields
	for key, value := range fields {
		if err := w.WriteField(key, value); err != nil {
			return nil, err
		}
	}

	// Add files
	for key, file := range files {
		f, err := os.Open(file)
		if err != nil {
			return nil, err
		}
		fw, err := w.CreateFormFile(key, file)
		if err != nil {
			return nil, err
		}
		if _, err = io.Copy(fw, f); err != nil {
			return nil, err
		}
	}

	if err := w.Close(); err != nil {
		return nil, err
	}

	req, err := http.NewRequest("POST", url, &b)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", w.FormDataContentType())
	req.Header.Add("X-HockeyAppToken", apiToken)

	return req, nil
}

func performRequest(request *http.Request) (string, int, error) {
	client := http.Client{}
	response, err := client.Do(request)
	if err != nil {
		// On error, any Response can be ignored
		return "", -1, fmt.Errorf("failed to perform request, error: %s", err)
	}

	// The client must close the response body when finished with it
	defer func() {
		if err := response.Body.Close(); err != nil {
			log.Errorf("Failed to close response body, error: %s", err)
		}
	}()

	body, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return "", response.StatusCode, fmt.Errorf("failed to read response body, error: %s", err)
	}

	if response.StatusCode < http.StatusOK || response.StatusCode > http.StatusMultipleChoices {
		return string(body), response.StatusCode, errors.New("non success status code")
	}

	return string(body), response.StatusCode, nil
}

// -----------------------
// --- Main
// -----------------------

func main() {
	configs := createConfigsModelFromEnvs()

	fmt.Println()
	configs.print()

	if err := configs.validate(); err != nil {
		log.Errorf("Issue with input: %s", err)
		if err := exportEnvironmentWithEnvman("BITRISE_XAMARIN_TEST_RESULT", "failed"); err != nil {
			log.Warnf("Failed to export environment: %s, error: %s", "BITRISE_XAMARIN_TEST_RESULT", err)
		}
		os.Exit(1)
	}

	//
	// Create request
	fmt.Println()
	log.Infof("Performing request")

	requestURL := hockeyAppUploadAppURL
	if configs.AppID != "" {
		requestURL = fmt.Sprintf(hockeyAppUploadNewVersionURLForm, configs.AppID)
	}

	mandatory := "0"
	if configs.Mandatory == "true" {
		mandatory = "1"
	}

	fields := map[string]string{
		"notes":            configs.Notes,
		"notes_type":       configs.NotesType,
		"notify":           configs.Notify,
		"status":           configs.Status,
		"mandatory":        mandatory,
		"tags":             configs.Tags,
		"commit_sha":       configs.CommitSHA,
		"build_server_url": configs.BuildServerURL,
		"repository_url":   configs.RepositoryURL,
	}

	files := map[string]string{
		"ipa": configs.IPAPath,
	}
	if configs.DSYMPath != "" {
		files["dsym"] = configs.DSYMPath
	}

	request, err := createRequest(requestURL, fields, files, configs.APIToken)
	if err != nil {
		failWithMessage("Failed to create request, error: %#v", err)
	}

	//
	// Perform request
	responseBody := ""
	responseStatusCode := -1

	if err := retry.Times(1).Wait(5 * time.Second).Try(func(attempt uint) error {
		body, statusCode, err := performRequest(request)
		if err != nil {
			log.Warnf("Attempt (%d) failed, error: %s", attempt+1, err)
			if !strings.Contains(err.Error(), "failed to perform request") {
				log.Warnf("Response status: %d", statusCode)
				log.Warnf("Body: %s", body)
			}
			return err
		}

		responseBody = body
		responseStatusCode = statusCode

		return nil
	}); err != nil {
		failWithMessage("Upload failed")
	}

	// Success
	log.Donef("Request succeeded with status code: %d", responseStatusCode)

	var responseModel ResponseModel
	if err := json.Unmarshal([]byte(responseBody), &responseModel); err != nil {
		log.Errorf("Failed to parse response body:\n%s", responseBody)
		failWithMessage("Error: %s", err)
	}

	if err := exportEnvironmentWithEnvman(hockeyAppDeployStatusKey, hockeyAppDeployStatusSuccess); err != nil {
		log.Errorf("Failed to export %s, value: %s, error: %#v", hockeyAppDeployStatusKey, hockeyAppDeployStatusSuccess, err)
	}

	fmt.Println()
	if responseModel.PublicURL != "" {
		if err := exportEnvironmentWithEnvman(hockeyAppDeployPublicURLKey, responseModel.PublicURL); err != nil {
			log.Errorf("Failed to export %s, value: %s, error: %s", hockeyAppDeployPublicURLKey, responseModel.PublicURL, err)
		} else {
			log.Printf("The Public URL is now available in the Environment Variable: %s\nvalue: %s", hockeyAppDeployPublicURLKey, responseModel.PublicURL)
		}
	}

	fmt.Println()
	if responseModel.BuildURL != "" {
		if err := exportEnvironmentWithEnvman(hockeyAppDeployBuildURLKey, responseModel.BuildURL); err != nil {
			log.Errorf("Failed to export %s, value: %s, error: %s", hockeyAppDeployBuildURLKey, responseModel.BuildURL, err)
		} else {
			log.Printf("The Build (direct download) URL is now available in the Environment Variable: %s\nvalue: %s", hockeyAppDeployBuildURLKey, responseModel.BuildURL)
		}
	}

	fmt.Println()
	if responseModel.ConfigURL != "" {
		if err := exportEnvironmentWithEnvman(hockeyAppDeployConfigURLKey, responseModel.ConfigURL); err != nil {
			log.Errorf("Failed to export %s, value: %s, error: %s", hockeyAppDeployConfigURLKey, responseModel.ConfigURL, err)
		} else {
			log.Printf("The Config URL is now available in the Environment Variable: %s\nvalue: %s", hockeyAppDeployConfigURLKey, responseModel.ConfigURL)
		}
	}
}
