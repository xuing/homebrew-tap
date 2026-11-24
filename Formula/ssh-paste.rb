# Written by .github/scripts/homebrew-formula.sh in xuing/ssh-please-paste-picture for
# each release. Changes made here are replaced by the next release.
class SshPaste < Formula
  desc "Paste screenshots into programs that run over SSH"
  homepage "https://github.com/xuing/ssh-please-paste-picture"
  url "https://github.com/xuing/ssh-please-paste-picture/releases/download/v0.1.12/ssh-paste.js"
  sha256 "43af0fb055f3e08d9b3eebfaf9b785c2d5956963cbef3c1ba69bf9affc3352a1"
  license "MIT"

  depends_on :macos

  resource "launcher" do
    url "https://github.com/xuing/ssh-please-paste-picture/releases/download/v0.1.12/ssh-paste-mac"
    sha256 "0807d448dd03e87fe131842f2fdc2339d7e96112dda7243c7ca26e0db8226cfa"
  end

  deny_network_access!

  def install
    libexec.install "ssh-paste.js"
    resource("launcher").stage do
      (libexec/"bin").install "ssh-paste-mac" => "ssh-paste"
    end
    chmod 0755, libexec/"bin/ssh-paste"
    bin.install_symlink libexec/"bin/ssh-paste"
  end

  def caveats
    <<~EOS
      Turn it on for a host:  ssh-paste --enable HOST
      Before brew uninstall ssh-paste, run: ssh-paste --uninstall
      It takes ssh-paste out of ~/.ssh/config, where ssh would otherwise
      keep calling the removed command for those hosts.
    EOS
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/ssh-paste --version").strip
    # --enable writes the opt path, which brew upgrade keeps, into ~/.ssh/config. ssh -G reads
    # no ssh config of the user's, so the test does not depend on it.
    ENV["HOME"] = testpath
    (testpath/"ssh").write <<~SH
      #!/bin/sh
      exec /usr/bin/ssh -F /dev/null "$@"
    SH
    chmod 0755, testpath/"ssh"
    ENV["SSH_PASTE_SSH"] = (testpath/"ssh").to_s
    system bin/"ssh-paste", "--enable", "127.0.0.1"
    assert_match "ProxyCommand '#{opt_libexec}/bin/ssh-paste' --proxy", (testpath/".ssh/config").read
    system bin/"ssh-paste", "--disable"
    refute_path_exists testpath/".ssh/config"
  end
end
