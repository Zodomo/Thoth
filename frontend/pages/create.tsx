import type { NextPage } from 'next'
import Layout from '~/layouts'
import Create from '~/create'

const Home: NextPage = () => {
  return (
    <Layout title="Create" description="Create a two-party contract.">
      <Create />
    </Layout>
  )
}

export default Home
