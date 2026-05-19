require_relative '8-post'

url = 'https://jsonplaceholder.typicode.com/posts'
body_params = { title: 'Try to Post', body: "Okay that's good", userId: 11, id: 101 }
post_request(url, body_params)
