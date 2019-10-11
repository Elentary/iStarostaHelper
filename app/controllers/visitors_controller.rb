require 'httparty'

class VisitorsController < ApplicationController
  skip_before_action :verify_authenticity_token

  URL           = "https://api.hackerearth.com/v3/code/run/"
  CLIENT_SECRET = "4e5953a8570b77e6109709b06256759b81c86b3b"
  SOURCE        = <<-eos
#include <iostream>
#include <random>
#include <vector>

const int INF = (int)1e9;

int n;
std::vector<std::vector<int>> a;
std::vector<std::string> lastName, firstName;

int main() {
    std::cin >> n;
    a.resize(n + 1);
    lastName.resize(n + 1);
    firstName.resize(n + 1);
    for (int i = 1; i <= n; ++i) {
        std::cin >> lastName[i] >> firstName[i];
        a[i].resize(n + 1);
        a[i][0] = i;
        for (int j = 1; j <= n; ++j) {
            double x;
            std::cin >> x;
            a[i][j] = -(int)round(x * 100);
        }
    }

    const int SEED = 1 ^ 9999;
    std::mt19937 gen(SEED);
    for (int i = 1; i <= n; ++i) {
        std::uniform_int_distribution<> uid(1, i);
        std::swap(a[i], a[uid(gen)]);
    }

    // Implementation can be found at e-maxx.ru/algo/assignment_hungary
    std::vector<int> u(n + 1), v(n + 1), p(n + 1), way(n + 1);
    for (int i = 1; i <= n; ++i) {
        p[0] = i;
        int j0 = 0;
        std::vector<int> minv(n + 1, INF);
        std::vector<bool> used(n + 1, false);
        do {
            used[j0] = true;
            int i0 = p[j0], delta = INF, j1;
            for (int j = 1; j <= n; ++j) {
                if (!used[j]) {
                    int cur = a[i0][j] - u[i0] - v[j];
                    if (cur < minv[j]) {
                        minv[j] = cur;
                        way[j] = j0;
                    }
                    if (minv[j] < delta) {
                        delta = minv[j];
                        j1 = j;
                    }
                }
            }
            for (int j = 0; j <= n; ++j) {
                if (used[j]) {
                    u[p[j]] += delta;
                    v[j] -= delta;
                } else
                    minv[j] -= delta;
            }
            j0 = j1;
        } while (p[j0] != 0);
        do {
            int j1 = way[j0];
            p[j0] = p[j1];
            j0 = j1;
        } while (j0);
    }

    for (int i = 1; i <= n; ++i) {
        int index = a[p[i]][0];
        std::cout << i << ". " << lastName[index] << " " << firstName[index] << std::endl;
    }

    return 0;
}
  eos

  def calculate
    url      = params[:data][:link].delete_suffix("edit?usp=sharing") + "export?format=xlsx"
    xls      = Roo::Spreadsheet.open(url, extension: :xlsx)
    last_row = 2
    (2..xls.sheet(0).last_row).each do |i|
      if xls.sheet(0).row(i).first == "ФИО \\ №"
        break
        ak
      end
      last_row = i
    end
    input = (last_row - 1).to_s + "\n"
    (2..last_row).each do |i|
      input += xls.sheet(0).row(i).join(' ') + "\n"
    end

    @seed = [0, [params[:data][:seed].to_i, 10000].min].max
    response = HTTParty.post(URL, body: {
      'client_secret': CLIENT_SECRET,
      'async':         0,
      'source':        SOURCE.sub('9999', @seed.to_s),
      'lang':          "CPP11",
      'time_limit':    5,
      'memory_limit':  262144,
      'input':         input
    }, headers:                         { 'Content-Type' => 'application/x-www-form-urlencoded' })
    @order   = JSON.parse(response.body)["run_status"]["output"].split("\n")
    @weblink = JSON.parse(response.body)["web_link"]
  end
end
