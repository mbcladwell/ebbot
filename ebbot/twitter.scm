(define-module (babweb lib twitter) 
 #:use-module (babweb lib env)
 #:use-module (web client)
 #:use-module (srfi srfi-19) ;; date time
 #:use-module (srfi srfi-1)  ;;list searching; delete-duplicates in list 
 #:use-module (srfi srfi-9)  ;;records
 #:use-module (web response)
 #:use-module (web request)
 #:use-module (oop goops) ;; class-of
 #:use-module (web uri)
 #:use-module (web client)
 #:use-module (web http)
 #:use-module (ice-9 rdelim)
 #:use-module (ice-9 i18n)   ;; internationalization
 #:use-module (ice-9 popen)
 #:use-module (ice-9 regex) ;;list-matches
 #:use-module (ice-9 receive)	     
 #:use-module (ice-9 string-fun)  ;;string-replace-substring
 #:use-module (ice-9 pretty-print)
 #:use-module (json)
 #:use-module (oauth oauth1)
 #:use-module (oauth oauth2)
 #:use-module (oauth oauth2 request)
 #:use-module (oauth oauth2 response)
 #:use-module (oauth utils)
 #:use-module (oauth request)
 #:use-module (oauth oauth1 client)
 #:use-module (oauth oauth1 utils)
 #:use-module (oauth oauth1 credentials)
 #:use-module (oauth oauth1 signature)
 #:use-module (rnrs bytevectors)
 #:use-module (ice-9 textual-ports)
 #:use-module (babweb lib image)
 #:use-module (babweb lib utilities)
 #:export (oauth2-post-tweet
	   oauth2-post-tweet-recurse
	   get-request-token
	   init-get-access-token
	   repeat-get-access-token
	   get-user-data
	   twurl-get-media-id
	   main
	   ))


(define-record-type <response-token>
  (make-response-token token_type access_token)
  response-token?
  (token_type response-token-type)
  (access_token response-token-access-token))

(define oauth-response-token-record (make-response-token "bearer" *oauth-access-token* ))

;#<<oauth1-response> token: "856105513800609792-ttQfcoxgrGJnwaLfjEdyagDjL9lfbTP" secret: "EfoSSaCHSnmfkhfU2r5oiU03cA6Kb6SLLAr7rxZO73Tfg" params: (("user_id" . "856105513800609792") ("screen_name" . "mbcladwell"))>


;; Client credentials:

;;     App Key === API Key === Consumer API Key === Consumer Key === Customer Key === oauth_consumer_key
;;     App Key Secret === API Secret Key === Consumer Secret === Consumer Key === Customer Key === oauth_consumer_secret
;;     Callback URL === oauth_callback
     

;; Temporary credentials:

;;     Request Token === oauth_token
;;     Request Token Secret === oauth_token_secret
;;     oauth_verifier
     

;; Token credentials:

;;     Access token === Token === resulting oauth_token
;;     Access token secret === Token Secret === resulting oauth_token_secret


(define (get-request-token k s)
;;(define (get-request-token )
  ;; returns a response: #<<oauth1-response> token: "Ia2k4gAAAAABb11DAAABgJn1fzQ" secret: "Pi8PTBLsyuE7tsfB1X2anChF3WyP1R7e" params: ()>
  ;; retrieve with  token: (oauth1-response-token a)
  ;;                secret: (oauth1-response-token-secret a)
  (let*( (uri "https://api.twitter.com/oauth/request_token")
	 ;;(credentials (make-oauth1-credentials oauth-access-token oauth-token-secret))
	 (credentials (make-oauth1-credentials k s))	 
;;	 (credentials (make-oauth1-credentials *oauth-consumer-key* *oauth-consumer-secret*))	 
;;	 (a  (oauth1-client-request-token uri credentials "oob"    ;;for pin
	 (a  (oauth1-client-request-token uri credentials "http://build-a-bot.biz/twittreg2"
					 #:method 'POST
					 #:params '()
					 #:signature oauth1-signature-hmac-sha1)))	
  a))




;;(define (get-user-data oauth_tokenv oauth-verifierv)
 ;;oauth_token is the token from get-request-token
  ;;oauth-verifier is the pin manually copied from the ____ page
  ;;output is a 'response object' as with get-request-token
(define (get-user-data oauth-verifier access-token)
  ;;access-token contains token, tokensecret
  ;;what is oauthVerifier inTwittService? comes from https://api.twitter.com/oauth/authenticate
  ;;so looks like the PIN
  (let* ((tokenv (oauth1-response-token access-token))
	 (secretv (oauth1-response-token-secret access-token))
	 (user-data-request (make-oauth-request "https://api.twitter.com/1.1/account/verify_credentials.json" 'GET '()))
	 (_ (oauth-request-add-params user-data-request `((oauth_consumer_key . ,*oauth-consumer-key*)
							  (oauth_nonce . ,(get-nonce 42 ""))
							  (oauth_timestamp . ,(oauth1-timestamp))
							  (oauth_token . ,tokenv)
							  (oauth_version . "1.0")					 
							  )))
	                                                       
	  (out (receive (response body)
		   (oauth1-http-request user-data-request #:body #f				
					#:signature oauth1-signature-hmac-sha1
					#:extra-headers '((access_token_secret . ,secretv)))
		 (oauth1-http-body->response response body)))
	  )    
    out
;; (receive (response body)
;; 	   	   (oauth1-http-request verifier-request #:body #f #:extra-headers '((oauth_callback_confirmed . "true")))
;; 	  	 (pretty-print (utf8->string body)))
    ))






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;July 2024 post Elon twiiter v2 api
;;https://developer.x.com/en/docs/authentication/oauth-2-0/user-access-token   PKCE instructions

;;step3
;;see guile-oauth/oauth/oauth2/client.scm
;; curl --location --request POST 'https://api.twitter.com/2/oauth2/token'
;; --header 'Content-Type: application/x-www-form-urlencoded'
;; --data-urlencode 'code=" authorization-code "'
;; --data-urlencode 'grant_type=authorization_code'
;; --data-urlencode 'token_type_hint=access_token'
;; --data-urlencode 'client_id=" *client-id* "'
;; --data-urlencode 'redirect_uri=" *redirecturi* "'
;; --data-urlencode 'code_verifier=abcdefgh'

;;https://api.x.com/oauth/authenticate?oauth_token=UvaijAAAAAABhb0tAAABkFlLYAs
(define (init-get-access-token authorization-code clid ruri datadir)
   ;;authorization-code from https://twitter.com/i/oauth2/authorize
  (let* ((uri "https://api.twitter.com/2/oauth2/token")
	 (qrylst-pre `(("grant_type" "authorization_code")
		       ("client_id" ,clid)
		       ("code" ,authorization-code)
		       ("code_verifier" "abcdefgh")
		       ("grant_type" "authorization_code")
		       ("redirect_uri" ,ruri)
		       ("token_type_hint" "access_token")
		       ))
	 ;;(_ (pretty-print qrylst-pre))
	 (qrylst (lst-to-query-string qrylst-pre "?"))
	 (body     (receive (response body)
      			   (http-request (string-append uri qrylst)
					 #:method 'POST
					 #:headers '((Content-Type . "x-www-form-urlencoded"))
			   #:body #f)
		     (utf8->string body)))
	 (alst (json-string->scm body))
	 (expires-in  (assoc-ref alst "expires_in"))
	 (expired (get-expired expires-in))
	 (lst2 (acons "expired" expired alst))
	 )
    (begin
       (if (access?  (string-append datadir "/oauth1_access_token_envs") F_OK) (delete-file (string-append datadir "/oauth1_access_token_envs")))
       (encrypt-alist lst2 (string-append datadir "/oauth1_access_token_envs")))))

(define (refresh-access-token refresh-token data-dir)
  (let* ((uri "https://api.twitter.com/2/oauth2/token")
	 (qrylst-pre `(("refresh_token" ,refresh-token)
		       ("client_id" ,*client-id*)
		       ("grant_type" "refresh_token")
		      ;; ("token_type_hint" "access_token")
		       ))
	  (qrylst (lst-to-query-string qrylst-pre "?"))	 
	 (body     (receive (response body)
      		       (http-request (string-append uri qrylst)
				     #:method 'POST
				     #:headers '((Content-Type . "x-www-form-urlencoded"))
				     #:body #f)
		     (utf8->string body)))
	 (alst (json-string->scm body))
;;	 (_ (pretty-print alst))
	 (expires-in  (assoc-ref alst "expires_in"))
	 (expired (get-expired expires-in))
	 (lst2 (acons "expired" expired alst))
	 )
     (begin
       (if (access?  (string-append data-dir "/oauth1_access_token_envs") F_OK) (delete-file (string-append data-dir "/oauth1_access_token_envs")))
       (encrypt-alist lst2 (string-append data-dir "/oauth1_access_token_envs"))
       (assoc-ref lst2 "access_token")
       )))
  

(define (repeat-get-access-token data-dir)
  ;;get the access token from access_token_envs
  ;;if it expired, refresh access_token_envs then return new access token
  (let* (
	 ;;(_ (pretty-print (string-append "data-dir: " data-dir)))
	
	 (current-accessenvs (decrypt-alist (string-append data-dir "/oauth1_access_token_envs")))
;;	 (_ (pretty-print "current-accessenvs: " ))
;;	 (_ (pretty-print current-accessenvs))
	 (refresh-token (assoc-ref current-accessenvs "refresh_token"))
	 (is-expired? (if (<  (assoc-ref current-accessenvs "expired") (time-second (current-time))) #t #f))
;;	 (_ (pretty-print  "is-expired?: "))
;;	 (_ (pretty-print is-expired?))	 
	 )
    (if is-expired?
	(refresh-access-token refresh-token data-dir)
	(assoc-ref current-accessenvs "access_token"))
    ))  
;; curl -X POST https://api.twitter.com/2/tweets -H "Authorization: Bearer "1516431938848006149-ZmM56NXft0k4rieBIH3Aj8A5727ALH" -H "Content-type: application/json" -d '{"text": "Hello World!"}'

      
;; curl --location --request POST 'https://api.twitter.com/2/oauth2/token' \
;; --header 'Content-Type: application/x-www-form-urlencoded' \
;; --data-urlencode 'code=VGNibzFWSWREZm01bjN1N3dicWlNUG1oa2xRRVNNdmVHelJGY2hPWGxNd2dxOjE2MjIxNjA4MjU4MjU6MToxOmFjOjE' \
;; --data-urlencode 'grant_type=authorization_code' \
;; --data-urlencode 'client_id=rG9n6402A3dbUJKzXTNX4oWHJ' \
;; --data-urlencode 'redirect_uri=https://www.example.com' \
;; --data-urlencode 'code_verifier=challenge'

;;https://stackoverflow.com/questions/77725780/error-fetching-oauth-credentials-missing-required-parameter-code-verifier

;;this worked!!
(define (get-access-token-curl authorization-code)
  ;;authorization-code from https://twitter.com/i/oauth2/authorize
  (let*(;;(media-id (mast-post-image-curl i))
;;	(media (if i (string-append "' --data-binary 'media_ids[]=" i ) ""))
;;	(reply (if r (string-append "' --data-binary 'in_reply_to_id=" r ) ""))
	(out-file (get-rand-file-name "f" "txt"))
	(command (string-append "curl -o " out-file " --location --request POST 'https://api.twitter.com/2/oauth2/token' --header 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'code=" authorization-code "' --data-urlencode 'grant_type=authorization_code' --data-urlencode 'token_type_hint=access_token' --data-urlencode 'client_id=" *client-id* "' --data-urlencode 'redirect_uri=" *redirecturi* "' --data-urlencode 'code_verifier=abcdefgh'"))
	(_ (pretty-print command))
	(_ (system command))
	(_ (sleep 1))
	(p  (open-input-file out-file))
	(lst  (json-string->scm (get-string-all p)))
	(expires-in (assoc-ref lst "expires_in"))
	(_ (delete-file out-file))
	(expired (get-expired expires-in))
	(lst2 (acons "expired" expired lst)))
    (encrypt-alist lst2 (string-append *data-dir* "/oauth1_access_token_envs"))))


;;must modify .twurlrc
(define (twurl-get-media-id pic-file-name)
  (let* ((command (string-append "twurl -X POST -H upload.twitter.com /1.1/media/upload.json?media_category=TWEET_IMAGE -f " pic-file-name " -F media"))
	 (js (call-command-with-output-to-string command))
	 (lst  (json-string->scm js)))
     (assoc-ref lst "media_id_string")))


(define (oauth2-post-tweet  text media-id reply-id data-dir)
  ;;  (oauth2-post-tweet  "hello world" #f #f *data-dir*)
  ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/authorizing-a-request
  ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/creating-a-signature
  ;;https://mail.gnu.org/archive/html/guile-user/2017-07/msg00067.html talks about application/json
  (let* (
	 (uri  "https://api.twitter.com/2/tweets")
	 (access-token (repeat-get-access-token data-dir))
	 (bearer (string-append "Bearer " access-token))
	 (lst `(("text". ,text)))
	 (lst (if media-id
		  (let* ((m (acons "media_ids" (vector media-id) '())))
		    (reverse  (acons "media" m lst)))
		  lst))
	 (lst (if reply-id (reverse (acons "reply" `(("in_reply_to_tweet_id" .  ,reply-id)) lst)) lst))
	 (data (scm->json-string lst))
	)
    (http-request uri 
		  #:method 'POST
		  #:headers `((content-type . (application/json))					     
			      (authorization . ,(parse-header 'authorization bearer)))
		  #:body data )))

(define (oauth2-post-tweet-recurse lst media-id reply-id data-dir hashtags counter)
  ;;list of tweets to post
  ;;reply-id initially #f
  ;;counter initially 0; counter is needed to identify reply-id in first round and use media-id if exists
  (if (null? (cdr lst))
      (begin
	(oauth2-post-tweet (string-append (car lst) " " hashtags) #f reply-id data-dir ))
      (if (eqv? counter 0)
	  (let* ((_ (pretty-print (string-append "counter is 0 i.e. the first tweet " )))
		 (body (receive (response body)	  
			   (oauth2-post-tweet (car lst) media-id reply-id data-dir)
			 body))
		 (_  (set! counter (+ counter 1))))
	    (oauth2-post-tweet-recurse  (cdr lst)  media-id (assoc-ref (assoc-ref (json-string->scm (utf8->string body)) "data") "id") data-dir hashtags counter))
	  (let* (
		 (body 	(receive (response body)	  
			    (oauth2-post-tweet (car lst) #f reply-id data-dir )
			  body)))
	    (begin
	      (set! counter (+ counter 1))
	     (oauth2-post-tweet-recurse  (cdr lst)  #f (assoc-ref (assoc-ref (json-string->scm (utf8->string body)) "data") "id")  data-dir hashtags counter))))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; guix shell -m manifest.scm -- guile -L /home/mbc/projects/babweb  -e '(babweb lib twitter)' -s /home/mbc/projects/babweb/babweb/lib/twitter.scm 

(define (main args)
  (let* ((counter (get-counter))
	 (all-excerpts (get-all-excerpts-alist))
	 (max-id (assoc-ref (car all-excerpts) "id"))
	 (new-counter (if (= counter max-id) 0 (+ counter 1)))
         (entity (find-by-id all-excerpts new-counter))
	 (_ (pretty-print *tweet-length*))
	 (tweets (chunk-a-tweet (assoc-ref entity "content") *tweet-length*))
	 (hashtags (get-all-hashtags-string))
	 (media-directive (assoc-ref entity "image"))
	 (image-file (if (string=? media-directive "none") #f (get-image-file-name media-directive)))
	 (media-id (if image-file  (twurl-get-media-id image-file) #f))
	 (_ (set-counter new-counter)))
    (oauth2-post-tweet-recurse tweets media-id #f *data-dir* hashtags 0)))


