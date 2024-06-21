(package-initialize)
(require 'cl)
(require 'org)
(require 'org-roam)
(require 'org-roam-export)
(require 'org-roam-dailies)

(setq make-backup-files 'nil)
(setq org-roam-directory (file-truename "~/org-roam-11ty/org-roam/"))
(setq org-roam-database-connector 'sqlite3)
(setq org-roam-db-location (concat org-roam-directory ".org-roam.db"))

(add-to-list 'safe-local-variable-values '(org-hugo-section . "daily"))
(setq org-hugo-base-dir "~/org-roam-11ty/")
(setq org-hugo-section ".")
(setq org-hugo-front-matter-format "yaml")

(defun make-inout-pair (f indir outdir)
  (let ((prefix-regex (format "^%s" indir))
        (md-file (concat (file-name-sans-extension f) ".md")))
    (cons f (replace-regexp-in-string prefix-regex outdir md-file))))

(defun newer (pair)
  (file-newer-than-file-p (car pair) (cdr pair)))

(defun doexport ()
  (org-roam-update-org-id-locations)
  (org-roam-db-sync)
  (let* ((indir (expand-file-name "~/org-roam-11ty/org-roam"))
         (outdir (expand-file-name "~/org-roam-11ty/content"))
         (search-path (file-name-as-directory indir))
         (org-files (directory-files-recursively search-path "\.org$"))
         (org-export-pair
          (mapcar (lambda(f) (make-inout-pair f indir outdir)) org-files))
         (org-export-update (remove-if-not 'newer org-export-pair))
         (num-files (length org-export-update))
         (cnt 1))
     (if (= 0 num-files)
        (message (format "No new org files to export in %s" search-path))
      (progn
        (message (format "Exporting %d files recursively from %S .."
                         num-files search-path))
        (dolist (org-export-pair org-export-update)
          (let ((org-file (car org-export-pair))
                (md-file (cdr org-export-pair)))
            (with-current-buffer (find-file-noselect org-file)
              (message (format "[%d/%d] Exporting %s" cnt num-files org-file))
              (org-hugo-export-wim-to-md :all-subtrees)
              (kill-buffer))
            (with-current-buffer (find-file-noselect md-file)
              (goto-char (point-min))
              (message (format "[%d/%d] Fix %s" cnt num-files md-file))
              (while (re-search-forward "{{< relref \"\\([a-zA-Z0-9_\\-]+\\)\\.md\" >}}" nil t)
                (replace-match "\\1"))
              (save-buffer)
              (kill-buffer))
            (setq cnt (1+ cnt))))
        (message "Done!")))))
(doexport)