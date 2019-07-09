import UIKit
import Moya

class ViewController: UITableViewController {
    var progressView = UIView()
    var repos = NSArray()

    override func viewDidLoad() {
        super.viewDidLoad()

        progressView.frame = CGRect(origin: .zero, size: CGSize(width: 0, height: 2))
        progressView.backgroundColor = .blue
        ///navigationBar
        navigationController?.navigationBar.addSubview(progressView)

        downloadRepositories("ashfurrow")
    }

    fileprivate func showAlert(_ title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - API Stuff

    func downloadRepositories(_ username: String) {
        gitHubProvider.request(.userRepositories(username)) { result in
            do {
                let response = try result.get()
                let value = try response.mapNSArray()
                self.repos = value
                self.tableView.reloadData()
            } catch {
                ///提示错误
                let printableError = error as CustomStringConvertible
                self.showAlert("GitHub Fetch", message: printableError.description)
            }
        }
    }

    func downloadZen() {
        gitHubProvider.request(.zen) { result in
            var message = "Couldn't access API"
            if case let .success(response) = result {
                ///转字符串
                let jsonString = try? response.mapString()
                message = jsonString ?? message
            }

            self.showAlert("Zen", message: message)
        }
    }

    func uploadGiphy() {
        ///上传
        giphyProvider.request(.upload(gif: Giphy.animatedBirdData),
                              callbackQueue: DispatchQueue.main,
                              progress: progressClosure,
                              completion: progressCompletionClosure)
    }

    func downloadMoyaLogo() {
        ///下载
        gitHubUserContentProvider.request(.downloadMoyaWebContent("logo_github.png"),
                                          callbackQueue: DispatchQueue.main,
                                          progress: progressClosure,
                                          completion: progressCompletionClosure)
    }

    // MARK: - Progress Helpers
    ///上传进度
    lazy var progressClosure: ProgressBlock = { response in
        UIView.animate(withDuration: 0.3) {
            self.progressView.frame.size.width = self.view.frame.size.width * CGFloat(response.progress)
        }
    }

    ///完成回调
    lazy var progressCompletionClosure: Completion = { result in
        let color: UIColor
        switch result {
        case .success:
            color = .green
        case .failure:
            color = .red
        }

        UIView.animate(withDuration: 0.3) {
            self.progressView.backgroundColor = color
            self.progressView.frame.size.width = self.view.frame.size.width
        }

        UIView.animate(withDuration: 0.3, delay: 1, options: [],
                       animations: {
                        self.progressView.alpha = 0
        },
                       completion: { _ in
                        self.progressView.backgroundColor = .blue
                        self.progressView.frame.size.width = 0
                        self.progressView.alpha = 1
        }
        )

    }

    // MARK: - User Interaction

    @IBAction func giphyWasPressed(_ sender: UIBarButtonItem) {
        uploadGiphy()
    }

    @IBAction func searchWasPressed(_ sender: UIBarButtonItem) {
        var usernameTextField: UITextField?

        let promptController = UIAlertController(title: "Username", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            if let username = usernameTextField?.text {
                self.downloadRepositories(username)
            }
        }
        promptController.addAction(okAction)
        promptController.addTextField { textField in
            usernameTextField = textField
        }
        present(promptController, animated: true, completion: nil)
    }

    @IBAction func zenWasPressed(_ sender: UIBarButtonItem) {
        downloadZen()
    }

    @IBAction func downloadWasPressed(_ sender: UIBarButtonItem) {
        downloadMoyaLogo()
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
        let repo = repos[indexPath.row] as? NSDictionary
        cell.textLabel?.text = repo?["name"] as? String
        return cell
    }
}
